import 'dart:async';
import 'package:bloc/bloc.dart';
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
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';

part 'conversations_state.dart';

@Injectable()
class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(this._profileRepository)
      : super(ConversationsState.initial()) {
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
        // Server-side status changed (typically 'pending' → 'paid').
        // Invalidate cache and re-fetch so mounted PaymentRequestCard
        // observers can pick up the new status. Silently no-ops if the
        // push payload doesn't include a parseable id.
        final identifier = event['type_identifier'];
        final id = identifier is int
            ? identifier
            : (identifier is String ? int.tryParse(identifier) : null);
        if (id == null) return;
        _paymentRequestCache.remove(id);
        unawaited(
          fetchPaymentRequest(id).then((updated) {
            if (updated?.id != null) {
              emit(state.copyWith(lastUpdatedPaymentRequestId: updated!.id));
            }
          }),
        );
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
    emit(
      state.copyWith(
        conversationsState: const ProcessState.success([]),
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
        Fluttertoast.showToast(msg: 'Action failed. Please try again.');
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
