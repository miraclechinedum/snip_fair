import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';

part 'conversations_state.dart';

@Injectable()
class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(this._profileRepository) : super(ConversationsState.initial()) {
    _chatNotificationsSubscription = null;
    _chatNotificationsSubscription = NotificationService.instance.updates.listen((event) {
      final type = event['type'] as String?;
      if (type == 'conversation') {
        final conversationId = event['type_identifier'] as String?;
        if (conversationId != null) {
          fetchChatMessages(conversationId, silent: true);
          fetchConversations(true);
        }
      }
    });
  }

  final ProfileRepository _profileRepository;

  StreamSubscription<Map<String, dynamic>>? _chatNotificationsSubscription;

  Future<void> fetchConversations([bool silent = false]) async {
    if (!silent) {
      emit(
        state.copyWith(
          conversationsState: ProcessState.loading(state.conversationsState.data),
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
        emit(
          state.copyWith(
            conversationsState: ProcessState.success(
              state.conversationsState.data!,
            ),
          ),
        );
      },
    );
  }

  Future<ChatConversation?> startConversation(String recipientId) async {
    Fluttertoast.showToast(msg: 'Starting conversation...');
    clearChatMessages();

    final response = await _profileRepository.startConversation(recipientId: recipientId);
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
              state.chatMessagesState.data!,
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

  void startPollingMessages(
    String conversationId, {
    Duration interval = const Duration(seconds: 10),
  }) {
    if (_polledConversationId == conversationId && (_pollingTimer?.isActive ?? false)) {
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

  void onLogout() {
    stopPollingMessages();
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
            createPaymentRequestState: ProcessState<PaymentRequest>.error(error),
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
        return data;
      },
      failure: (error) {
        Fluttertoast.showToast(msg: 'Action failed. Please try again.');
        return null;
      },
    );
  }

  void resetCreatePaymentRequestState() {
    emit(
      state.copyWith(
        createPaymentRequestState: const ProcessState<PaymentRequest>.init(null),
      ),
    );
  }

  @override
  Future<void> close() {
    _chatNotificationsSubscription?.cancel();
    return super.close();
  }
}
