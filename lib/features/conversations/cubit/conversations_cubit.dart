import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/services/analytics_service.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request_card_payment.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';
import 'package:snip_fair/core/services/peach_deposit_reconciler.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/features/conversations/data/payment_request_attempt_store.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';

part 'conversations_state.dart';

@Injectable()
class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(
    this._profileRepository, {
    PaymentRequestAttemptStore? attemptStore,
  })  : _attemptStore = attemptStore ?? const LocalPaymentRequestAttemptStore(),
        super(ConversationsState.initial()) {
    _chatNotificationsSubscription = null;
    _chatNotificationsSubscription =
        NotificationService.instance.updates.listen((event) {
      final type = event['type'] as String?;
      if (type == 'conversation') {
        final conversationId = event['type_identifier'] as String?;
        if (conversationId != null) {
          fetchChatMessages(conversationId, silent: true);
          fetchConversations(true);
        }
      } else if (type == 'payment_request') {
        unawaited(onPaymentRequestPush(event['type_identifier']));
      }
    });
  }

  final ProfileRepository _profileRepository;

  StreamSubscription<Map<String, dynamic>>? _chatNotificationsSubscription;

  Future<void> fetchConversations([bool silent = false]) async {
    if (!silent) {
      emit(
        state.copyWith(
          conversationsState:
              ProcessState.loading(state.conversationsState.data),
        ),
      );
    }

    final result = await _profileRepository.getChatConversations();

    result.when(
      success: (data) {
        emit(
          state.copyWith(
            conversationsState: ProcessState.success(data),
          ),
        );
      },
      failure: (error) {
        // Keep whatever list we already had. `data` is null before the very
        // first successful fetch, so a bang here crashed the badge-refresh
        // path whenever the first call failed.
        emit(
          state.copyWith(
            conversationsState: ProcessState.success(
              state.conversationsState.data ?? const <ChatConversation>[],
            ),
          ),
        );
      },
    );
  }

  Future<ChatConversation?> startConversation(String recipientId) async {
    Fluttertoast.showToast(msg: 'Starting conversation...');
    clearChatMessages();

    final response =
        await _profileRepository.startConversation(recipientId: recipientId);
    unawaited(fetchConversations());
    return response.when(
      success: (data) => data,
      failure: (error) {
        Fluttertoast.showToast(msg: 'Failed to start conversation');
        return null;
      },
    );
  }

  Future<void> fetchChatMessages(
    String conversationId, {
    bool loadMore = false,
    bool silent = false,
  }) async {
    if (!loadMore && !silent) {
      clearChatMessages();
      emit(
        state.copyWith(
          chatMessagesState: ProcessState.loading(state.chatMessagesState.data),
          chatPaginationData: const PaginationData(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          chatPaginationData: PaginationData(
            isLoadingMore: loadMore,
            nextPageCursor: state.chatPaginationData.nextPageCursor,
            prevPageCursor: state.chatPaginationData.prevPageCursor,
          ),
        ),
      );
    }

    final result = await _profileRepository.getChatMessages(conversationId);

    result.when(
      success: (data) {
        if (loadMore) {
          final currentMessages = state.chatMessagesState.data ?? [];
          final updatedMessages = [...currentMessages, ...?data.data];
          emit(
            state.copyWith(
              chatMessagesState: ProcessState.success(updatedMessages),
              chatPaginationData: PaginationData(
                nextPageCursor: data.nextCursor,
                prevPageCursor: data.prevCursor,
                hasReachedMax: data.nextCursor == null,
              ),
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            chatMessagesState: ProcessState.success(data.data ?? []),
            chatPaginationData: PaginationData(
              nextPageCursor: data.nextCursor,
              prevPageCursor: data.prevCursor,
              hasReachedMax: data.nextCursor == null,
            ),
          ),
        );
      },
      failure: (error) {
        stopPollingMessages();
        emit(
          state.copyWith(
            chatMessagesState: ProcessState.success(
              state.chatMessagesState.data ?? const <ChatMessage>[],
            ),
          ),
        );
      },
    );
  }

  Future<void> handleSendMessage({
    required String text,
    required String conversationId,
    required String? currentUserId,
    required String? otherUserId,
  }) async {
    if (text.trim().isEmpty) return;
    final currentMessages = state.chatMessagesState.data ?? [];
    // TODO: Replace with actual API call to send message
    final newMessage = ChatMessage(
      id: currentMessages.length + 1,
      conversationId: conversationId,
      senderId: currentUserId,
      receiverId: otherUserId,
      text: text,
      isRead: false,
      createdAt: DateTime.now(),
    );

    currentMessages.insert(0, newMessage);

    emit(
      state.copyWith(
        chatMessagesState: ProcessState.success(
          List<ChatMessage>.from(currentMessages),
        ),
      ),
    );
    Fluttertoast.showToast(msg: 'Sending message...');
    final response = await _profileRepository.sendMessage(
      conversationId: conversationId,
      text: text,
    );

    response.when(
      success: (data) {
        // fetchChatMessages(conversationId);

        Fluttertoast.showToast(msg: 'Message sent');
        fetchConversations(true);
      },
      failure: (error) {
        Fluttertoast.showToast(msg: 'Failed to send message');

        emit(
          state.copyWith(
            chatMessagesState: ProcessState.success(
              List<ChatMessage>.from(currentMessages),
            ),
          ),
        );
      },
    );
  }

  Future<void> markMessagesAsRead(
    String conversationId,
    String messageId,
  ) async {
    final result = await _profileRepository.markMessageAsRead(
      conversationId: conversationId,
      messageId: messageId,
    );

    result.when(
      success: (data) {
        fetchChatMessages(conversationId, silent: true);
        fetchConversations(true);
      },
      failure: (error) {
        // Handle error if needed
      },
    );
  }

  /// Conversation ids whose inbound backlog we've already flushed this
  /// session. Without this the chat screen re-issues the same PATCHes on
  /// every rebuild/poll tick.
  final Set<String> _readFlushInFlight = {};

  /// Clears the unread state for a whole conversation in one pass.
  ///
  /// Called once when the chat screen opens (and again whenever new inbound
  /// messages arrive while it's on screen). Replaces the previous pattern of
  /// firing `markMessagesAsRead` from inside `ListView.itemBuilder`, which
  /// issued one request per unread message per build frame and left the
  /// badge stale until the app was reopened.
  ///
  /// Optimistically zeroes the local `unreadCount` / `isRead` flags and
  /// decrements the polled scalar so the badge clears immediately, then
  /// re-syncs from the server. No payment or appointment state is touched.
  Future<void> markConversationAsRead(
    String conversationId, {
    required String? currentUserId,
  }) async {
    if (_readFlushInFlight.contains(conversationId)) return;

    final messages = state.chatMessagesState.data ?? const <ChatMessage>[];
    final unread = messages
        .where(
          (m) =>
              m.id != null &&
              (m.isRead ?? false) == false &&
              m.senderId != currentUserId,
        )
        .toList(growable: false);

    if (unread.isEmpty) return;
    _readFlushInFlight.add(conversationId);

    // Optimistic local clear so the row badge and the app-bar badge drop
    // straight away rather than waiting a poll cycle.
    _applyLocalReadClear(conversationId, unread.length);

    try {
      for (final message in unread) {
        final result = await _profileRepository.markMessageAsRead(
          conversationId: conversationId,
          messageId: message.id.toString(),
        );
        if (result is Failure) break;
      }
    } finally {
      _readFlushInFlight.remove(conversationId);
    }

    if (isClosed) return;
    await fetchChatMessages(conversationId, silent: true);
    if (isClosed) return;
    await fetchConversations(true);
    unawaited(_fetchUnreadConversationsCount());
  }

  /// Local-only projection of "this conversation is now read". Purely a
  /// display concern — the server remains authoritative and the follow-up
  /// refetch overwrites this.
  void _applyLocalReadClear(String conversationId, int clearedCount) {
    final conversations = state.conversationsState.data;
    final updated = conversations?.map((c) {
      if (c.id?.toString() != conversationId) return c;
      c.unreadCount = 0;
      return c;
    }).toList(growable: false);

    final polled = state.unreadConversationsCount;
    emit(
      state.copyWith(
        conversationsState: updated == null
            ? state.conversationsState
            : ProcessState.success(updated),
        unreadConversationsCount:
            polled == null ? null : (polled - clearedCount).clamp(0, polled),
      ),
    );
  }

  void clearChatMessages() {
    emit(
      state.copyWith(
        chatMessagesState: const ProcessState.success([]),
        chatPaginationData: const PaginationData(),
      ),
    );
  }

  //Write a functions that start polling for new messages every 30 seconds
  Timer? _pollingTimer;
  String? _polledConversationId;
  bool _isPollingFetchInProgress = false;

  // Separate polling loop for the CONVERSATIONS LIST (drives the unread
  // badge on the message icon). Independent from the per-chat message
  // polling above.
  Timer? _conversationsPollingTimer;
  bool _isConversationsPollingInProgress = false;

  void startPollingMessages(
    String conversationId, {
    Duration interval = const Duration(seconds: 10),
  }) {
    if (_polledConversationId == conversationId &&
        (_pollingTimer?.isActive ?? false)) {
      return;
    }
    stopPollingMessages();
    _polledConversationId = conversationId;

    // Immediate fetch before starting periodic polling
    fetchChatMessages(conversationId);

    _pollingTimer = Timer.periodic(interval, (_) async {
      if (_isPollingFetchInProgress) return;
      _isPollingFetchInProgress = true;
      try {
        await fetchChatMessages(conversationId, silent: true);
      } catch (_) {
        // ignore errors during polling
      } finally {
        _isPollingFetchInProgress = false;
      }
    });
  }

  void stopPollingMessages() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _polledConversationId = null;
    _isPollingFetchInProgress = false;
  }

  /// Polls the conversations list every [interval] to keep the unread-badge
  /// count fresh while the app is foregrounded. MainScreen starts this in
  /// initState / on `AppLifecycleState.resumed` and stops it on
  /// paused/inactive/hidden/detached so the timer doesn't run when the user
  /// isn't watching.
  ///
  /// Idempotent — calling while already active is a no-op.
  ///
  /// Note: currently backed by `GET /conversations`, which returns full
  /// conversation objects with embedded message previews (not a cheap count
  /// endpoint). A dedicated `/conversations/unread-count` is queued as a
  /// backend follow-up; swapping to it will be a one-line change here.
  void startPollingConversations({
    Duration interval = const Duration(seconds: 4),
  }) {
    if (_conversationsPollingTimer?.isActive ?? false) return;
    // Immediate fetch so the badges are fresh at the moment polling starts
    // (foreground / resume) — don't make the user wait a full interval on
    // top of app resume.
    _fetchUnreadConversationsCount();
    _conversationsPollingTimer = Timer.periodic(interval, (_) async {
      if (_isConversationsPollingInProgress) return;
      _isConversationsPollingInProgress = true;
      try {
        await _fetchUnreadConversationsCount();
      } catch (_) {
        // Ignore transient failures — the next tick retries.
      } finally {
        _isConversationsPollingInProgress = false;
      }
    });
  }

  void stopPollingConversations() {
    _conversationsPollingTimer?.cancel();
    _conversationsPollingTimer = null;
    _isConversationsPollingInProgress = false;
  }

  /// Called by the conversations polling loop. Hits the cheap
  /// `/conversations/unread-count` endpoint (~95% smaller payload than the
  /// full list) and stores the scalar in state for the badge widget.
  /// The full conversations list is still refreshed on-demand by other
  /// paths (message-icon tap, pull-to-refresh, chat push).
  Future<void> _fetchUnreadConversationsCount() async {
    final result = await _profileRepository.getConversationsUnreadCount();
    result.when(
      success: (count) {
        emit(state.copyWith(unreadConversationsCount: count));
      },
      failure: (_) {
        // Silently ignore — next tick retries.
      },
    );
  }

  void onLogout() {
    stopPollingMessages();
    stopPollingConversations();
    clearChatMessages();
    // Payment requests, attempts and unresolved card payments belong to the
    // signed-out account; none of it may carry over to the next one.
    _paymentRequestCache.clear();
    _paymentsInFlight.clear();
    _pollTokens.clear();
    final owner = _attemptOwnerId;
    _attemptOwnerId = null;
    _persistedAttempts = {};
    if (owner != null) {
      unawaited(
        _attemptStore.clear(owner).catchError((Object e) {
          paymentRequestLog('Clearing payment attempts failed: $e');
        }),
      );
    }
    emit(
      state.copyWith(
        conversationsState: const ProcessState.success([]),
        paymentProgress: const {},
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Payment Request methods
  // ---------------------------------------------------------------------------

  /// In-memory cache so each PaymentRequestCard can look up its data
  /// without triggering a full state rebuild on every fetch.
  final Map<int, PaymentRequest> _paymentRequestCache = {};

  PaymentRequest? getCachedPaymentRequest(int id) => _paymentRequestCache[id];

  Future<PaymentRequest?> fetchPaymentRequest(int id) async {
    final result = await _profileRepository.getPaymentRequest(id);
    return result.when(
      success: (data) {
        _paymentRequestCache[id] = data;
        return data;
      },
      failure: (_) => null,
    );
  }

  Future<void> createPaymentRequest({
    required int recipientId,
    required String title,
    required List<Map<String, dynamic>> items,
    String? description,
    int? appointmentId,
    int? expiresInHours,
  }) async {
    emit(
      state.copyWith(
        createPaymentRequestState: const ProcessState<PaymentRequest>.loading(),
      ),
    );
    final result = await _profileRepository.createPaymentRequest(
      recipientId: recipientId,
      title: title,
      description: description,
      items: items,
      appointmentId: appointmentId,
      expiresInHours: expiresInHours,
    );
    result.when(
      success: (data) {
        _paymentRequestCache[data.id!] = data;
        emit(
          state.copyWith(
            createPaymentRequestState: ProcessState.success(data),
          ),
        );
        // Re-fetch messages so the new payment_request message appears
        if (data.conversationId != null) {
          fetchChatMessages(data.conversationId.toString(), silent: true);
        }
      },
      failure: (error) {
        emit(
          state.copyWith(
            createPaymentRequestState:
                ProcessState<PaymentRequest>.error(error),
          ),
        );
      },
    );
  }

  Future<PaymentRequest?> respondToPaymentRequest(
    int id,
    String action,
  ) async {
    final result = await _profileRepository.respondToPaymentRequest(id, action);
    return result.when(
      success: (data) {
        _paymentRequestCache[id] = data;
        if (action == 'pay') {
          unawaited(
            AnalyticsService.instance.logPurchase(
              amount: data.totalAmount ?? 0,
              transactionId: data.id?.toString() ?? id.toString(),
            ),
          );
          unawaited(_refreshMoneyStateAfterPay());
        }
        return data;
      },
      failure: (error) {
        paymentRequestLog(
          'POST /payment-requests/$id/$action failed: ${_describeError(error)}',
        );
        Fluttertoast.showToast(msg: paymentFailureMessage(error));
        return null;
      },
    );
  }

  /// After a successful pay action, refresh the wallet/transactions (customer
  /// side) and earnings (stylist side) so the UI reflects the payment without
  /// requiring an app restart. Guarded by role so each device only calls the
  /// endpoints relevant to its user.
  ///
  /// Read-only refresh: no local balance calculation, no synthesized
  /// transaction record — the backend remains the sole source of truth for
  /// any money value displayed.
  Future<void> _refreshMoneyStateAfterPay() async {
    final appState = getIt<AppCubit>().state;
    if (appState.isCustomer) {
      final cubit = getIt<CustomerProfileMgtCubit>();
      unawaited(cubit.getWallet(true));
      unawaited(cubit.getWalletTransactions());
    }
    if (appState.isStylist) {
      final earnings = getIt<EarningsCubit>();
      unawaited(earnings.getEarnings());
      unawaited(earnings.fetchTransactions(isInitial: true));
    }
  }

  // ---------------------------------------------------------------------------
  // Paying a payment request (customer side)
  //
  // Wallet: `POST /payment-requests/{id}/pay` (no body).
  // Card:   `POST /payment-requests/{id}/pay` with `payment_method: card`,
  //         the existing Peach hosted checkout, then the payer-only
  //         `GET /payment-requests/{id}/payments/{paymentId}/status` until it
  //         answers `paid: true` (the only success signal) or a final outcome.
  // Top-up (only when the customer chooses it, e.g. while native card is
  //         unavailable or to cover a wallet shortfall): `POST /payment/topup`,
  //         the deposit status endpoint, then the wallet `/pay`.
  // The request is shown as paid only on `code: paid` or `paid: true`.
  //
  // Progress lives in [ConversationsState.paymentProgress] so every card for
  // a request renders the same phase. The top-up endpoints are called
  // directly rather than through CustomerProfileMgtCubit: that cubit's top-up
  // state drives listeners on other screens (booking, wallet) that may still
  // be mounted under the chat.
  // ---------------------------------------------------------------------------

  /// Requests whose Pay Now flow is between the tap and its first phase (the
  /// method sheet is open). Phases cover everything after that.
  final Set<int> _paymentsInFlight = {};

  final PaymentRequestAttemptStore _attemptStore;

  /// Background status checks after the quick check: about 3 minutes of
  /// back-off (2 s, 4 s, 8 s, 15 s, then every 30–60 s), never longer.
  @visibleForTesting
  static PeachPollSchedule paymentStatusPolling = const PeachPollSchedule(
    delays: [
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 15),
      Duration(seconds: 30),
      Duration(seconds: 30),
      Duration(seconds: 30),
      Duration(seconds: 60),
    ],
    maxDuration: Duration(minutes: 3),
  );

  /// How long the card may show "Confirming…" for one status check before it
  /// offers Check Payment Status instead. The request itself carries on.
  @visibleForTesting
  static Duration paymentStatusCheckTimeout = const Duration(seconds: 15);

  /// Restored attempts older than this are dropped: a top-up that completed
  /// long ago is already in the wallet whatever the app does.
  @visibleForTesting
  static Duration paymentAttemptMaxAge = const Duration(days: 7);

  @visibleForTesting
  static Future<void> Function(Duration) paymentPollSleep =
      (duration) => Future<void>.delayed(duration);

  @visibleForTesting
  static DateTime Function() paymentClock = DateTime.now;

  /// One status request per deposit at a time; concurrent checks share it.
  final Map<String, Future<ApiResult<PaymentReconciliation>>> _statusInFlight =
      {};

  /// The live background polling loop per request (its token); replacing or
  /// removing a token stops the old loop at its next wake-up.
  final Map<int, Object> _pollTokens = {};
  final Map<int, Future<void>> _pollLoops = {};
  bool _pollingPaused = false;

  /// The customer whose attempts are persisted; null until restored.
  String? _attemptOwnerId;
  Map<int, PaymentRequestAttempt> _persistedAttempts = {};

  /// A `payment_request` push: the server-side status changed (typically
  /// 'accepted' → 'paid'). Invalidates the cache and re-fetches so mounted
  /// cards pick up the new status — on every push, including repeats for the
  /// same request. No-ops when the payload has no parseable id.
  Future<void> onPaymentRequestPush(Object? identifier) async {
    final id = identifier is int
        ? identifier
        : (identifier is String ? int.tryParse(identifier) : null);
    if (id == null) return;
    _paymentRequestCache.remove(id);
    await _refreshPaymentRequest(id);
  }

  PaymentRequestPaymentProgress paymentProgressFor(int id) =>
      state.paymentProgress[id] ?? const PaymentRequestPaymentProgress();

  /// Claims the Pay Now slot for [id]. False while another attempt for the
  /// request is open or any payment phase for it is in progress.
  bool beginPaymentRequestPayment(int id) {
    if (paymentProgressFor(id).phase.isBusy) return false;
    return _paymentsInFlight.add(id);
  }

  void endPaymentRequestPayment(int id) => _paymentsInFlight.remove(id);

  /// Why Pay Now cannot proceed for [pr], as a customer-facing message, or
  /// null when it can. Mirrors the backend's `can_pay` so obviously invalid
  /// requests fail fast with a reason instead of a server round-trip.
  String? payNowBlocker(PaymentRequest pr) {
    if (pr.id == null) {
      return 'This payment request could not be loaded. Please reopen the chat.';
    }
    if (pr.canPay == false || !(pr.isAccepted || pr.isPending)) {
      return 'This payment request can no longer be paid.';
    }
    final amount = pr.totalAmount;
    if (amount == null || amount <= 0) {
      return 'This payment request has no amount to pay. '
          'Please ask your stylist to send it again.';
    }
    return null;
  }

  /// Fresh wallet balance to offer alongside the payment options, or null when
  /// it could not be loaded. Null is not zero: the sheet still opens and the
  /// backend remains the judge of whether the wallet can cover the payment.
  Future<num?> loadWalletBalanceForPayment() async {
    final result = await _profileRepository.getWallet();
    return result.when(
      success: (wallet) {
        if (wallet.balance == null) {
          paymentRequestLog('GET wallet returned no balance');
        }
        return wallet.balance;
      },
      failure: (error) {
        paymentRequestLog('GET wallet failed: ${_describeError(error)}');
        return null;
      },
    );
  }

  // --- Wallet ----------------------------------------------------------------

  /// Pays [id] from the wallet (`POST /payment-requests/{id}/pay`, no body).
  /// After a verified card top-up (phase
  /// [PaymentRequestPaymentPhase.topUpSucceededPaymentPending]) a retryable
  /// failure keeps that phase and its deposit, so the customer retries the
  /// wallet payment and is never charged by card again.
  Future<void> payFromWallet(int id) async {
    final current = paymentProgressFor(id);
    if (current.phase.isBusy || current.phase.isUnresolvedTopUp) return;
    final afterTopUp = current.phase ==
        PaymentRequestPaymentPhase.topUpSucceededPaymentPending;
    final depositId = afterTopUp ? current.depositId : null;
    _setProgress(
      id,
      PaymentRequestPaymentPhase.payingFromWallet,
      depositId: depositId,
    );

    paymentRequestLog(
      'Calling POST /payment-requests/$id/pay '
      '(after card top-up: $afterTopUp, deposit=${depositId ?? 'none'})',
    );
    final result = await _profileRepository.payPaymentRequest(id);
    await result.when(
      success: (pay) async {
        if (pay.isPaid) {
          final paid = pay.paymentRequest;
          if (paid != null) _cacheAndNotify(id, paid);
          _setProgress(
            id,
            PaymentRequestPaymentPhase.successful,
            message: 'Payment successful.',
          );
          return;
        }
        // A 2xx without `code: paid` is not a payment.
        paymentRequestLog(
          'POST /payment-requests/$id/pay returned code=${pay.code}',
        );
        await _walletPaymentFailed(
          id,
          depositId: depositId,
          retryable: true,
          reason: 'Payment could not be completed. Please try again.',
        );
      },
      failure: (error) async {
        paymentRequestLog(
          'POST /payment-requests/$id/pay failed: ${_describeError(error)}',
        );
        switch (error.code) {
          case 'already_paid':
            await _confirmAlreadyPaid(id, error, depositId: depositId);
          case 'insufficient_wallet_balance':
            await _awaitWalletFunds(id, error, afterTopUp: afterTopUp);
          case 'card_payment_in_progress':
            // A card checkout for this request could still take the money:
            // check that attempt; never pay a second time from the wallet.
            final paymentId = _blockingCardPaymentId(error);
            if (paymentId != null && depositId == null) {
              await _refreshPaymentRequest(id);
              _setProgress(
                id,
                PaymentRequestPaymentPhase.topUpUnknown,
                cardPaymentId: paymentId,
                message: 'A card payment for this request is still in '
                    'progress, so your wallet was not charged. '
                    'Tap Check Payment Status.',
              );
              return;
            }
            await _walletPaymentFailed(
              id,
              depositId: depositId,
              retryable: true,
              reason: paymentFailureMessage(error),
            );
          case 'payment_request_not_payable':
          case 'payment_request_expired':
          case 'not_payer':
          case 'unsupported_payment_method':
          case 'payment_method_unavailable':
            await _walletPaymentFailed(
              id,
              depositId: depositId,
              retryable: false,
              reason: paymentFailureMessage(error),
            );
          default:
            // `payment_failed` (rolled back), a network failure or an
            // unrecognised error: nothing was debited that a retry could
            // duplicate — `/pay` pays at most once.
            await _walletPaymentFailed(
              id,
              depositId: depositId,
              retryable: true,
              reason: paymentFailureMessage(error),
            );
        }
      },
    );
  }

  /// `already_paid`: confirm against `GET /payment-requests/{id}` before
  /// treating it as success.
  Future<void> _confirmAlreadyPaid(
    int id,
    RemoteException error, {
    required String? depositId,
  }) async {
    final refreshed = await _refreshPaymentRequest(id);
    if (refreshed?.isPaid ?? false) {
      _setProgress(
        id,
        PaymentRequestPaymentPhase.successful,
        message: 'This payment request has already been paid.',
      );
      return;
    }
    await _walletPaymentFailed(
      id,
      depositId: depositId,
      retryable: true,
      refreshRequest: false,
      reason: paymentFailureMessage(error),
    );
  }

  /// `insufficient_wallet_balance`: record the backend's own shortfall. The
  /// customer chooses whether to add it by card; nothing is charged here.
  Future<void> _awaitWalletFunds(
    int id,
    RemoteException error, {
    required bool afterTopUp,
  }) async {
    final shortfall = error.numberField('shortfall');
    final hasShortfall = shortfall != null && shortfall > 0;
    final shortText = hasShortfall
        ? 'Your wallet is still short by '
            '${shortfall.toDouble().formatAmount()}.'
        : paymentFailureMessage(error);
    await _refreshPaymentRequest(id);
    _setProgress(
      id,
      PaymentRequestPaymentPhase.awaitingWalletFunds,
      shortfall: hasShortfall ? shortfall : null,
      walletBalance: error.numberField('wallet_balance'),
      requiredAmount: error.numberField('required_amount'),
      message: afterTopUp
          ? 'Your card payment succeeded and the money is in your wallet, '
              'but this request is not paid yet. $shortText'
          : shortText,
    );
  }

  Future<void> _walletPaymentFailed(
    int id, {
    required String? depositId,
    required bool retryable,
    required String reason,
    bool refreshRequest = true,
  }) async {
    if (refreshRequest) await _refreshPaymentRequest(id);
    if (depositId == null) {
      _setProgress(id, PaymentRequestPaymentPhase.failed, message: reason);
      return;
    }
    const inWallet = 'Your card payment succeeded and the money is in your '
        'wallet, but this request is not paid yet.';
    if (retryable) {
      _setProgress(
        id,
        PaymentRequestPaymentPhase.topUpSucceededPaymentPending,
        depositId: depositId,
        message: '$inWallet $reason Tap Retry Payment to pay from your wallet.',
      );
    } else {
      _setProgress(
        id,
        PaymentRequestPaymentPhase.failed,
        message: '$inWallet $reason',
      );
    }
  }

  // --- Card --------------------------------------------------------------------

  /// Starts a Peach wallet top-up of [amount] for request [id] and returns the
  /// hosted checkout to open, or null (with the reason in the request's
  /// progress). Refuses while a previous card payment is unresolved or its
  /// money is already in the wallet — a new top-up would be a second charge.
  ///
  /// [amount] is the request's total when the customer picks Card, or the
  /// backend's `shortfall` when they add missing wallet funds.
  Future<CheckoutPaymentData?> startCardTopUp(
    int id, {
    required num amount,
  }) async {
    final current = paymentProgressFor(id);
    if (current.phase.isBusy) return null;
    if (current.phase.isUnresolvedTopUp ||
        current.phase ==
            PaymentRequestPaymentPhase.topUpSucceededPaymentPending) {
      paymentRequestLog(
        'Card top-up not started for payment request $id: '
        'previous attempt is ${current.phase.name}',
      );
      _setProgress(
        id,
        current.phase,
        depositId: current.depositId,
        message: current.phase.isUnresolvedTopUp
            ? 'Your previous card payment is still being confirmed. '
                'Tap Check Payment Status first.'
            : 'Your card payment is already in your wallet. '
                'Tap Retry Payment to pay from your wallet.',
      );
      return null;
    }
    if (amount <= 0) {
      paymentRequestLog('Card top-up refused for $id: amount=$amount');
      _setProgress(
        id,
        PaymentRequestPaymentPhase.failed,
        message: paymentStartFailedMessage,
      );
      return null;
    }

    _setProgress(id, PaymentRequestPaymentPhase.initializingTopUp);
    peachLog('Payment request $id: card top-up initialization started');
    final result = await _profileRepository.initializeWalletTopUp(
      amount: amount,
    );
    return result.when(
      success: (checkout) {
        if (!checkout.canOpenCheckout) {
          // Shape only — never the redirect URL or checkout id.
          paymentRequestLog(
            'Card top-up for payment request $id returned an unusable '
            'checkout: initialized=${checkout.isInitialized} '
            'hasDeposit=${checkout.depositId != null} '
            'hasRedirect=${checkout.redirectUrl?.isNotEmpty ?? false}',
          );
          _setProgress(
            id,
            PaymentRequestPaymentPhase.failed,
            message: paymentStartFailedMessage,
          );
          return null;
        }
        peachLog(
          'Payment request $id: checkout created '
          'deposit=${checkout.depositId}',
        );
        _setProgress(
          id,
          PaymentRequestPaymentPhase.checkoutOpen,
          depositId: checkout.depositId,
        );
        return checkout;
      },
      failure: (error) {
        paymentRequestLog(
          'POST ${AuthPath.customerPaymentTopUp} failed for payment request '
          '$id: ${_describeError(error)}',
        );
        _setProgress(
          id,
          PaymentRequestPaymentPhase.failed,
          message: topUpFailureMessage(error),
        );
        return null;
      },
    );
  }

  /// Starts (or resumes) the request's native card checkout and returns it,
  /// or null with the reason in the request's progress. Refuses while an
  /// earlier card payment is unresolved or its money is already in the
  /// wallet. Laravel reuses a pending attempt's checkout, so reopening never
  /// opens a second one; a `paid` status is the only proof of payment.
  Future<PaymentRequestCardCheckout?> startCardCheckout(int id) async {
    final current = paymentProgressFor(id);
    if (current.phase.isBusy) return null;
    if (current.phase.isUnresolvedTopUp ||
        current.phase ==
            PaymentRequestPaymentPhase.topUpSucceededPaymentPending) {
      _setProgress(
        id,
        current.phase,
        depositId: current.depositId,
        cardPaymentId: current.cardPaymentId,
        message: current.phase.isUnresolvedTopUp
            ? 'Your previous card payment is still being confirmed. '
                'Tap Check Payment Status first.'
            : 'Your card payment is already in your wallet. '
                'Tap Retry Payment to pay from your wallet.',
      );
      return null;
    }

    _setProgress(id, PaymentRequestPaymentPhase.initializingCardCheckout);
    peachLog('Payment request $id: native card checkout started');
    final result = await _profileRepository.startPaymentRequestCardCheckout(id);
    return result.when(
      success: (checkout) {
        final request = checkout.paymentRequest;
        if (request != null) _cacheAndNotify(id, request);
        if (!checkout.canOpenCheckout) {
          paymentRequestLog(
            'Card checkout for $id unusable: '
            'hasPayment=${checkout.paymentId != null} '
            'hasRedirect=${checkout.redirectUrl?.isNotEmpty ?? false}',
          );
          _setProgress(
            id,
            PaymentRequestPaymentPhase.failed,
            message: paymentStartFailedMessage,
          );
          return null;
        }
        peachLog(
          'Payment request $id: checkout ready payment=${checkout.paymentId} '
          'reused=${checkout.reused}',
        );
        _setProgress(
          id,
          PaymentRequestPaymentPhase.checkoutOpen,
          cardPaymentId: checkout.paymentId,
        );
        return checkout;
      },
      failure: (error) async {
        paymentRequestLog(
          'POST /payment-requests/$id/pay (card) failed: '
          '${_describeError(error)}',
        );
        await _cardCheckoutRefused(id, error);
        return null;
      },
    );
  }

  /// Why `POST /pay` (card) started nothing — each answer handled as Laravel
  /// means it. Never falls back to another payment method by itself.
  Future<void> _cardCheckoutRefused(int id, RemoteException error) async {
    switch (error.code) {
      case 'payment_method_unavailable':
        _setProgress(
          id,
          PaymentRequestPaymentPhase.cardUnavailable,
          message: cardUnavailableMessage,
        );
      case 'card_payment_unresolved':
      case 'checkout_initializing':
      case 'card_payment_in_progress':
        final paymentId = _blockingCardPaymentId(error);
        if (paymentId == null) {
          _setProgress(
            id,
            PaymentRequestPaymentPhase.failed,
            message: paymentFailureMessage(error),
          );
          return;
        }
        // An earlier attempt may still take the money: check it instead.
        _setProgress(
          id,
          PaymentRequestPaymentPhase.topUpUnknown,
          cardPaymentId: paymentId,
          message: 'A previous card payment for this request has not been '
              'confirmed yet. Tap Check Payment Status.',
        );
        await _checkNow(id, trigger: 'unresolved attempt');
        _startBackgroundPolling(id);
      case 'already_paid':
        await _confirmAlreadyPaid(id, error, depositId: null);
      default:
        // `checkout_initialization_failed` (nothing charged), `checkout_conflict`,
        // not payable / expired / not the payer, or a network failure.
        await _refreshPaymentRequest(id);
        _setProgress(
          id,
          PaymentRequestPaymentPhase.failed,
          message: paymentFailureMessage(error),
        );
    }
  }

  /// The `payment.payment_id` Laravel names when an earlier card attempt
  /// blocks this action.
  static String? _blockingCardPaymentId(RemoteException error) {
    final payment = error.responseBody?['payment'];
    final id = payment is Map ? payment['payment_id']?.toString() : null;
    return id == null || id.isEmpty ? null : id;
  }

  static const cardUnavailableMessage =
      "Card payment isn't available for payment requests yet. Nothing was "
      'charged. You can pay from your wallet, or top up your wallet by card '
      'and then pay from it.';

  /// The hosted checkout is no longer in front of the customer — X, the
  /// shopper-result page, a dismissal or an error. Closing is never proof of
  /// payment *or* of failure: one quick check, bounded for the UI, then quiet
  /// background polling while the outcome is unresolved. Repeated calls are
  /// no-ops once the first has moved the phase on.
  Future<void> onCardCheckoutClosed(int id) async {
    if (paymentProgressFor(id).phase !=
        PaymentRequestPaymentPhase.checkoutOpen) {
      return;
    }
    await _checkNow(id, trigger: 'checkout closed');
    _startBackgroundPolling(id);
  }

  /// Check Payment Status: one status check of the request's unresolved
  /// card top-up. Available whenever an attempt is pending or unknown,
  /// including after background polling has ended.
  Future<void> checkCardPaymentStatus(int id) =>
      _checkNow(id, trigger: 'manual');

  /// Re-checks every unresolved card payment once and resumes background
  /// polling for those still unresolved (app resume / restore).
  Future<void> recheckUnresolvedPayments() async {
    _pollingPaused = false;
    final unresolved = state.paymentProgress.entries
        .where((entry) => entry.value.phase.isUnresolvedTopUp)
        .map((entry) => entry.key)
        .toList();
    for (final id in unresolved) {
      await _checkNow(id, trigger: 'resume');
      _startBackgroundPolling(id, restart: true);
    }
  }

  /// Stops background polling while the app is not in the foreground. The
  /// deposits are kept; [recheckUnresolvedPayments] resumes.
  void pausePaymentStatusPolling() {
    _pollingPaused = true;
    _pollTokens.clear();
  }

  /// Completes when every background polling loop has finished.
  @visibleForTesting
  Future<void> debugPaymentPollingIdle() =>
      Future.wait([..._pollLoops.values]);

  Future<void> _checkNow(int id, {required String trigger}) async {
    final current = paymentProgressFor(id);
    final cardPaymentId = current.cardPaymentId;
    if (cardPaymentId != null) {
      return _checkCardNow(id, cardPaymentId, trigger: trigger);
    }
    final depositId = current.depositId;
    if (depositId == null ||
        !(current.phase.isUnresolvedTopUp ||
            current.phase == PaymentRequestPaymentPhase.checkoutOpen)) {
      paymentRequestLog(
        'Status check ($trigger) skipped for $id: '
        'phase=${current.phase.name} deposit=${depositId ?? 'none'}',
      );
      return;
    }
    paymentRequestLog(
      'Status check started ($trigger): request=$id deposit=$depositId',
    );
    _setProgress(
      id,
      PaymentRequestPaymentPhase.verifyingTopUp,
      depositId: depositId,
    );
    final check = await _reconciler()
        .reconcile(
          depositId,
          isVerified: (payment) => payment.isVerified,
          shouldStop: () => isClosed,
          logLabel: 'payment request $id deposit',
        )
        .timeout(
          paymentStatusCheckTimeout,
          onTimeout: () {
            paymentRequestLog('Status check for $id outlasted the UI wait');
            return const PeachDepositCheck(PeachDepositVerdict.unknown);
          },
        );
    await _applyVerdict(id, depositId, check, quiet: false);
  }

  void _startBackgroundPolling(int id, {bool restart = false}) {
    final progress = paymentProgressFor(id);
    final cardPaymentId = progress.cardPaymentId;
    if (cardPaymentId != null) {
      return _startCardPolling(id, cardPaymentId, restart: restart);
    }
    final depositId = progress.depositId;
    if (_pollingPaused ||
        isClosed ||
        depositId == null ||
        !progress.phase.isUnresolvedTopUp ||
        (!restart && _pollTokens.containsKey(id))) {
      return;
    }
    final token = Object();
    _pollTokens[id] = token;

    bool stopped() {
      final now = paymentProgressFor(id);
      return isClosed ||
          _pollingPaused ||
          !identical(_pollTokens[id], token) ||
          now.depositId != depositId ||
          !(now.phase.isUnresolvedTopUp ||
              now.phase == PaymentRequestPaymentPhase.verifyingTopUp);
    }

    final schedule = paymentStatusPolling;
    final loop = () async {
      final check = await _reconciler().reconcile(
        depositId,
        isVerified: (payment) => payment.isVerified,
        initialDelay: schedule.delays.first,
        retryDelays: schedule.delays.skip(1).toList(),
        maxDuration: schedule.maxDuration,
        shouldStop: stopped,
        logLabel: 'payment request $id deposit (background)',
      );
      final wasStopped = stopped();
      if (identical(_pollTokens[id], token)) _pollTokens.remove(id);
      if (wasStopped || (check.payment == null && check.error == null)) {
        return;
      }
      await _applyVerdict(id, depositId, check, quiet: true);
    }();
    _pollLoops[id] = loop;
    unawaited(
      loop.whenComplete(() {
        if (identical(_pollLoops[id], loop)) _pollLoops.remove(id);
      }),
    );
  }

  /// Applies a status verdict for [depositId] unless the attempt moved on
  /// meanwhile (resolved, paid or replaced) — a late or repeated result can
  /// never overwrite newer state. [quiet] results (background polling) don't
  /// raise a message for a still-unresolved outcome.
  Future<void> _applyVerdict(
    int id,
    String depositId,
    PeachDepositCheck check, {
    required bool quiet,
  }) async {
    if (isClosed) return;
    final current = paymentProgressFor(id);
    if (current.depositId != depositId ||
        !(current.phase.isUnresolvedTopUp ||
            current.phase == PaymentRequestPaymentPhase.verifyingTopUp)) {
      paymentRequestLog(
        'Stale status verdict ignored for $id: deposit=$depositId '
        'verdict=${check.verdict.name} now=${current.phase.name}',
      );
      return;
    }
    paymentRequestLog(
      'Status verdict for request $id deposit $depositId: '
      '${check.verdict.name} (http=${check.error?.statusCode ?? (check.payment != null ? 200 : 'none')} '
      'status=${check.payment?.status ?? check.error?.responseBody?['status'] ?? 'none'} '
      'settled=${check.payment?.settled}${quiet ? ', background' : ''})',
    );
    switch (check.verdict) {
      case PeachDepositVerdict.verified:
        peachLog('Payment request $id: top-up verified, paying from wallet');
        _pollTokens.remove(id);
        _setProgress(
          id,
          PaymentRequestPaymentPhase.topUpSucceededPaymentPending,
          depositId: depositId,
        );
        await payFromWallet(id);
      case PeachDepositVerdict.failed:
        _pollTokens.remove(id);
        _setProgress(
          id,
          PaymentRequestPaymentPhase.failed,
          message: 'Your card payment failed. You can try again.',
        );
      case PeachDepositVerdict.cancelled:
        _pollTokens.remove(id);
        _setProgress(
          id,
          PaymentRequestPaymentPhase.cancelled,
          message: 'Card payment was cancelled.',
        );
      case PeachDepositVerdict.pending:
        _setUnresolved(
          id,
          PaymentRequestPaymentPhase.topUpPending,
          depositId: depositId,
          quiet: quiet,
          message: 'Your card payment is still being confirmed. '
              'Tap Check Payment Status to try again.',
        );
      case PeachDepositVerdict.unknown:
        final status = check.error?.statusCode;
        if (status == 404 || status == 422) {
          // Definitively not a verifiable Peach payment of this customer.
          _pollTokens.remove(id);
          _setProgress(
            id,
            PaymentRequestPaymentPhase.failed,
            message: "We couldn't verify this card payment. If you were "
                'charged, the money will appear in your wallet — '
                'otherwise please contact support.',
          );
        } else {
          _setUnresolved(
            id,
            PaymentRequestPaymentPhase.topUpUnknown,
            depositId: depositId,
            quiet: quiet,
            message: "We couldn't confirm your card payment yet. "
                'Tap Check Payment Status before paying again.',
          );
        }
    }
  }

  // --- Native card status -----------------------------------------------------

  /// One check of the native card attempt [paymentId], bounded for the UI.
  Future<void> _checkCardNow(
    int id,
    String paymentId, {
    required String trigger,
  }) async {
    final current = paymentProgressFor(id);
    if (!(current.phase.isUnresolvedTopUp ||
        current.phase == PaymentRequestPaymentPhase.checkoutOpen)) {
      paymentRequestLog('Card status check ($trigger) skipped for $id: '
          'phase=${current.phase.name}');
      return;
    }
    paymentRequestLog(
      'Card status check started ($trigger): request=$id payment=$paymentId',
    );
    _setProgress(
      id,
      PaymentRequestPaymentPhase.verifyingTopUp,
      cardPaymentId: paymentId,
    );
    final result = await _fetchCardStatusOnce(id, paymentId)
        .then<ApiResult<PaymentRequestCardPaymentStatus>?>((r) => r)
        .timeout(
      paymentStatusCheckTimeout,
      onTimeout: () {
        paymentRequestLog('Card status check for $id outlasted the UI wait');
        return null;
      },
    );
    await _applyCardStatus(id, paymentId, result, quiet: false);
  }

  void _startCardPolling(int id, String paymentId, {bool restart = false}) {
    final progress = paymentProgressFor(id);
    if (_pollingPaused ||
        isClosed ||
        !progress.phase.isUnresolvedTopUp ||
        (!restart && _pollTokens.containsKey(id))) {
      return;
    }
    final token = Object();
    _pollTokens[id] = token;

    bool stopped() {
      final now = paymentProgressFor(id);
      return isClosed ||
          _pollingPaused ||
          !identical(_pollTokens[id], token) ||
          now.cardPaymentId != paymentId ||
          !(now.phase.isUnresolvedTopUp ||
              now.phase == PaymentRequestPaymentPhase.verifyingTopUp);
    }

    final schedule = paymentStatusPolling;
    final loop = () async {
      final started = paymentClock();
      for (final wait in schedule.delays) {
        if (paymentClock().difference(started) + wait > schedule.maxDuration) {
          break;
        }
        await paymentPollSleep(wait);
        if (stopped()) break;
        final result = await _fetchCardStatusOnce(id, paymentId);
        if (stopped()) break;
        await _applyCardStatus(id, paymentId, result, quiet: true);
        if (!paymentProgressFor(id).phase.isUnresolvedTopUp) break;
      }
      if (identical(_pollTokens[id], token)) _pollTokens.remove(id);
    }();
    _pollLoops[id] = loop;
    unawaited(
      loop.whenComplete(() {
        if (identical(_pollLoops[id], loop)) _pollLoops.remove(id);
      }),
    );
  }

  /// Applies a native card status unless the attempt moved on meanwhile.
  /// `paid: true` is the only success; everything not final keeps the
  /// attempt to be checked again.
  Future<void> _applyCardStatus(
    int id,
    String paymentId,
    ApiResult<PaymentRequestCardPaymentStatus>? result, {
    required bool quiet,
  }) async {
    if (isClosed) return;
    final current = paymentProgressFor(id);
    if (current.cardPaymentId != paymentId ||
        !(current.phase.isUnresolvedTopUp ||
            current.phase == PaymentRequestPaymentPhase.verifyingTopUp)) {
      paymentRequestLog('Stale card status ignored for $id: '
          'payment=$paymentId now=${current.phase.name}');
      return;
    }
    if (result == null) {
      _setUnresolved(
        id,
        PaymentRequestPaymentPhase.topUpUnknown,
        quiet: quiet,
        cardPaymentId: paymentId,
        message: "We couldn't confirm your card payment yet. "
            'Tap Check Payment Status before paying again.',
      );
      return;
    }
    await result.when(
      success: (status) async {
        final request = status.paymentRequest;
        if (request != null) _cacheAndNotify(id, request);
        if (status.paid) {
          _pollTokens.remove(id);
          _setProgress(
            id,
            PaymentRequestPaymentPhase.successful,
            message: status.message ?? 'Payment successful.',
          );
          return;
        }
        if (status.isFailedOrCancelled) {
          _pollTokens.remove(id);
          _setProgress(
            id,
            status.paymentStatus == 'cancelled'
                ? PaymentRequestPaymentPhase.cancelled
                : PaymentRequestPaymentPhase.failed,
            message: status.message ??
                'The card payment was not completed. You have not been '
                    'charged. You can try again.',
          );
          return;
        }
        if (status.isEndedUnpaid) {
          _pollTokens.remove(id);
          _setProgress(
            id,
            PaymentRequestPaymentPhase.failed,
            message: status.message ??
                'This card payment did not pay the request. '
                    'Please contact Snipfair support.',
          );
          return;
        }
        // pending, requires_review, successful-but-not-paid or unknown.
        _setUnresolved(
          id,
          PaymentRequestPaymentPhase.topUpPending,
          quiet: quiet,
          cardPaymentId: paymentId,
          message: status.message ??
              'Your card payment is still being confirmed. '
                  'Tap Check Payment Status to try again.',
        );
      },
      failure: (error) async {
        final code = error.statusCode;
        if (code == 403 || code == 404) {
          // Definitively not this customer's attempt for this request.
          _pollTokens.remove(id);
          await _refreshPaymentRequest(id);
          _setProgress(
            id,
            PaymentRequestPaymentPhase.failed,
            message: "We couldn't verify this card payment. If you were "
                'charged, please contact Snipfair support.',
          );
          return;
        }
        // 503 (Peach unreachable), network failure, 5xx: unknown.
        _setUnresolved(
          id,
          PaymentRequestPaymentPhase.topUpUnknown,
          quiet: quiet,
          cardPaymentId: paymentId,
          message: "We couldn't confirm your card payment yet. "
              'Tap Check Payment Status before paying again.',
        );
      },
    );
  }

  /// One status request per card attempt at a time.
  final Map<String, Future<ApiResult<PaymentRequestCardPaymentStatus>>>
      _cardStatusInFlight = {};

  Future<ApiResult<PaymentRequestCardPaymentStatus>> _fetchCardStatusOnce(
    int id,
    String paymentId,
  ) {
    final inFlight = _cardStatusInFlight[paymentId];
    if (inFlight != null) return inFlight;
    final request = _profileRepository
        .getPaymentRequestCardPaymentStatus(id, paymentId)
        .whenComplete(() {
      _cardStatusInFlight.remove(paymentId);
    });
    _cardStatusInFlight[paymentId] = request;
    return request;
  }

  void _setUnresolved(
    int id,
    PaymentRequestPaymentPhase phase, {
    required bool quiet,
    required String message,
    String? depositId,
    String? cardPaymentId,
  }) {
    final current = paymentProgressFor(id);
    if (quiet && current.phase.isUnresolvedTopUp) {
      if (current.phase == phase) return;
      _setProgress(
        id,
        phase,
        depositId: depositId,
        cardPaymentId: cardPaymentId,
        message: current.message,
      );
      return;
    }
    _setProgress(
      id,
      phase,
      depositId: depositId,
      cardPaymentId: cardPaymentId,
      message: message,
    );
  }

  PeachDepositReconciler _reconciler() => PeachDepositReconciler(
        _fetchStatusOnce,
        sleep: paymentPollSleep,
        now: paymentClock,
      );

  Future<ApiResult<PaymentReconciliation>> _fetchStatusOnce(String depositId) {
    final inFlight = _statusInFlight[depositId];
    if (inFlight != null) return inFlight;
    // Block body: an arrow would return the removed future (this one) to
    // whenComplete, which would then wait on itself forever.
    final request =
        _profileRepository.reconcilePeachPayment(depositId).whenComplete(() {
      _statusInFlight.remove(depositId);
    });
    _statusInFlight[depositId] = request;
    return request;
  }

  // --- Persistence -------------------------------------------------------------

  /// Loads [ownerId]'s unresolved card attempts after an app (re)start and
  /// re-checks their deposits. A restored attempt never opens a checkout: it
  /// is verified, and a verified top-up continues to the wallet `/pay`.
  Future<void> restorePaymentAttempts({required String ownerId}) async {
    if (_attemptOwnerId == ownerId) {
      await recheckUnresolvedPayments();
      return;
    }
    _attemptOwnerId = ownerId;
    final now = paymentClock();
    final stored = _attemptStore.load(ownerId);
    final kept = <int, PaymentRequestAttempt>{};
    for (final attempt in stored) {
      final age = now.difference(attempt.updatedAt);
      if (age > paymentAttemptMaxAge || age < const Duration(days: -1)) {
        continue;
      }
      final previous = kept[attempt.requestId];
      if (previous == null || attempt.updatedAt.isAfter(previous.updatedAt)) {
        kept[attempt.requestId] = attempt;
      }
    }
    _persistedAttempts = kept;
    if (kept.length != stored.length) _writeAttempts();
    paymentRequestLog('Restored ${kept.length} unresolved card payment(s)');

    for (final attempt in kept.values) {
      if (paymentProgressFor(attempt.requestId).phase !=
          PaymentRequestPaymentPhase.idle) {
        continue;
      }
      _setProgress(
        attempt.requestId,
        PaymentRequestPaymentPhase.topUpUnknown,
        depositId: attempt.isNativeCard ? null : attempt.depositId,
        cardPaymentId: attempt.cardPaymentId,
      );
    }
    await recheckUnresolvedPayments();
  }

  /// A native card attempt is kept while its outcome may still change.
  static const _persistedCardPhases = {
    PaymentRequestPaymentPhase.checkoutOpen,
    PaymentRequestPaymentPhase.verifyingTopUp,
    PaymentRequestPaymentPhase.topUpPending,
    PaymentRequestPaymentPhase.topUpUnknown,
  };

  static const _persistedPhases = {
    PaymentRequestPaymentPhase.checkoutOpen,
    PaymentRequestPaymentPhase.verifyingTopUp,
    PaymentRequestPaymentPhase.topUpPending,
    PaymentRequestPaymentPhase.topUpUnknown,
    PaymentRequestPaymentPhase.topUpSucceededPaymentPending,
    PaymentRequestPaymentPhase.payingFromWallet,
  };

  /// Keeps the persisted record for [id] in step with its progress: kept
  /// while a deposit is unresolved or verified-but-unpaid, removed once the
  /// attempt is paid, failed, cancelled or otherwise finished.
  void _syncPersistedAttempt(int id, PaymentRequestPaymentProgress progress) {
    if (_attemptOwnerId == null) return;
    final previous = _persistedAttempts[id];
    final cardPaymentId = progress.cardPaymentId;
    if (cardPaymentId != null) {
      if (!_persistedCardPhases.contains(progress.phase)) {
        if (previous == null) return;
        _persistedAttempts = {..._persistedAttempts}..remove(id);
      } else {
        if (previous?.cardPaymentId == cardPaymentId) return;
        _persistedAttempts = {
          ..._persistedAttempts,
          id: PaymentRequestAttempt.card(
            requestId: id,
            cardPaymentId: cardPaymentId,
            updatedAt: paymentClock(),
          ),
        };
      }
      _writeAttempts();
      return;
    }
    final depositId = progress.depositId;
    if (depositId != null && _persistedPhases.contains(progress.phase)) {
      final verified = progress.phase ==
              PaymentRequestPaymentPhase.topUpSucceededPaymentPending ||
          progress.phase == PaymentRequestPaymentPhase.payingFromWallet;
      if (previous?.depositId == depositId &&
          previous?.verified == verified) {
        return;
      }
      _persistedAttempts = {
        ..._persistedAttempts,
        id: PaymentRequestAttempt(
          requestId: id,
          depositId: depositId,
          verified: verified,
          // The attempt's age counts from when its deposit was first
          // recorded, so restarts cannot keep a stale attempt alive forever.
          updatedAt: previous?.depositId == depositId
              ? previous!.updatedAt
              : paymentClock(),
        ),
      };
    } else {
      if (previous == null) return;
      _persistedAttempts = {..._persistedAttempts}..remove(id);
    }
    _writeAttempts();
  }

  void _writeAttempts() {
    final owner = _attemptOwnerId;
    if (owner == null) return;
    unawaited(
      _attemptStore
          .save(owner, _persistedAttempts.values.toList())
          .catchError((Object e) {
        paymentRequestLog('Saving payment attempts failed: ${e.runtimeType}');
      }),
    );
  }

  // --- Shared ----------------------------------------------------------------

  void _setProgress(
    int id,
    PaymentRequestPaymentPhase phase, {
    String? depositId,
    String? cardPaymentId,
    String? message,
    num? shortfall,
    num? walletBalance,
    num? requiredAmount,
  }) {
    if (isClosed) return;
    paymentRequestLog('Payment request $id: phase=${phase.name}');
    final progress = PaymentRequestPaymentProgress(
      phase: phase,
      depositId: depositId,
      cardPaymentId: cardPaymentId,
      message: message,
      revision: paymentProgressFor(id).revision + 1,
      shortfall: shortfall,
      walletBalance: walletBalance,
      requiredAmount: requiredAmount,
    );
    emit(
      state.copyWith(
        paymentProgress: {...state.paymentProgress, id: progress},
      ),
    );
    _syncPersistedAttempt(id, progress);
  }

  void _cacheAndNotify(int id, PaymentRequest request) {
    _paymentRequestCache[id] = request;
    if (isClosed) return;
    emit(
      state.copyWith(
        lastUpdatedPaymentRequestId: id,
        paymentRequestUpdateSeq: state.paymentRequestUpdateSeq + 1,
      ),
    );
  }

  Future<PaymentRequest?> _refreshPaymentRequest(int id) async {
    final refreshed = await fetchPaymentRequest(id);
    if (refreshed != null) _cacheAndNotify(id, refreshed);
    return refreshed;
  }

  /// Customer-facing text for a failed payment request call. Prefers the
  /// backend's own message (e.g. 'Insufficient wallet balance.') and
  /// otherwise says what kind of failure happened.
  static String paymentFailureMessage(RemoteException error) {
    final serverMessage = (error.errorResponse?.message ?? '').trim();
    if (error.kind == RemoteExceptionKind.server &&
        serverMessage.isNotEmpty &&
        !_mapperPlaceholderMessages.contains(serverMessage)) {
      return serverMessage;
    }
    switch (error.kind) {
      case RemoteExceptionKind.noInternet:
      case RemoteExceptionKind.timeout:
      case RemoteExceptionKind.network:
      case RemoteExceptionKind.unexpected:
        return "We couldn't reach Snipfair. "
            'Check your connection and try again.';
      case RemoteExceptionKind.cancellation:
      case RemoteExceptionKind.http:
      case RemoteExceptionKind.server:
        return error.isServerInternalError
            ? 'Snipfair is having trouble right now. Please try again shortly.'
            : 'Something went wrong. Please try again.';
    }
  }

  static const paymentStartFailedMessage =
      'Unable to start payment. Please try again.';

  /// Placeholder texts the shared HTTP error mapper substitutes when it
  /// cannot read the backend body; they are not messages from Laravel.
  static const _mapperPlaceholderMessages = {
    'Server Error',
    'Unexpected Server error',
    'An errorfrrr occured',
  };

  /// Customer-facing text for a failed `POST /payment/topup`.
  ///
  /// Expected backend refusals (4xx with a message, e.g. "Selected payment
  /// method is currently not available" or a validation error) are shown as
  /// written. 404, 401 and 5xx keep a safe generic message — their bodies
  /// are routing/server internals, not customer copy.
  @visibleForTesting
  static String topUpFailureMessage(RemoteException error) {
    final status = error.statusCode;
    final serverMessage = (error.errorResponse?.message ?? '').trim();
    final isExpectedRefusal = error.kind == RemoteExceptionKind.server &&
        status != null &&
        status >= 400 &&
        status < 500 &&
        status != 401 &&
        status != 404;
    if (isExpectedRefusal &&
        serverMessage.isNotEmpty &&
        !_mapperPlaceholderMessages.contains(serverMessage)) {
      return serverMessage;
    }
    switch (error.kind) {
      case RemoteExceptionKind.noInternet:
      case RemoteExceptionKind.timeout:
      case RemoteExceptionKind.network:
      case RemoteExceptionKind.unexpected:
        return paymentFailureMessage(error);
      case RemoteExceptionKind.cancellation:
      case RemoteExceptionKind.http:
      case RemoteExceptionKind.server:
        return paymentStartFailedMessage;
    }
  }

  /// One-line diagnostic for a failed call: kind, HTTP status, error code and
  /// the backend message, flattened and truncated. Never includes headers,
  /// request bodies, tokens or checkout URLs.
  static String _describeError(RemoteException error) {
    final raw = error.errorResponse?.message ?? '';
    final flat = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final message = flat.isEmpty
        ? 'none'
        : flat.length > 160
            ? '${flat.substring(0, 160)}…'
            : flat;
    return 'kind=${error.kind.name} status=${error.statusCode ?? 'none'} '
        'code=${error.code ?? 'none'} message="$message"';
  }

  void resetCreatePaymentRequestState() {
    emit(
      state.copyWith(
        createPaymentRequestState:
            const ProcessState<PaymentRequest>.init(null),
      ),
    );
  }

  @override
  Future<void> close() {
    _chatNotificationsSubscription?.cancel();
    return super.close();
  }
}

/// Concise debug-only diagnostics for the payment request pay flow. Never pass
/// tokens, headers, card data or raw payloads.
void paymentRequestLog(String message) {
  if (!kDebugMode) return;
  debugPrint('[PAYMENT_REQUEST] $message');
}
