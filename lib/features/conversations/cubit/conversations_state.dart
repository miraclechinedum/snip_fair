part of 'conversations_cubit.dart';

class ConversationsState extends Equatable {
  factory ConversationsState.initial() {
    return const ConversationsState._(
      conversationsState: ProcessState.init(null),
      chatMessagesState: ProcessState.init(null),
      chatPaginationData: PaginationData(),
      createPaymentRequestState: ProcessState.init(null),
    );
  }

  const ConversationsState._({
    required this.conversationsState,
    required this.chatMessagesState,
    required this.chatPaginationData,
    required this.createPaymentRequestState,
    this.lastUpdatedPaymentRequestId,
    this.unreadConversationsCount,
  });

  final ProcessState<List<ChatConversation>> conversationsState;
  final ProcessState<List<ChatMessage>> chatMessagesState;
  final PaginationData chatPaginationData;
  final ProcessState<PaymentRequest> createPaymentRequestState;

  /// Ticks up when a `payment_request` push handler refreshes the cache for
  /// a specific id. `PaymentRequestCard` observes this to know when to re-read
  /// its data from the cubit's in-memory cache.
  final int? lastUpdatedPaymentRequestId;

  /// Total unread messages across all conversations, populated by the
  /// 4-second polling loop against `GET /conversations/unread-count`.
  /// Preferred over the client-derived sum from `conversationsState` — the
  /// count endpoint is cheap and always current.
  final int? unreadConversationsCount;

  @override
  List<Object?> get props => [
        conversationsState,
        chatMessagesState,
        chatPaginationData,
        createPaymentRequestState,
        lastUpdatedPaymentRequestId,
        unreadConversationsCount,
      ];

  ConversationsState copyWith({
    ProcessState<List<ChatConversation>>? conversationsState,
    ProcessState<List<ChatMessage>>? chatMessagesState,
    PaginationData? chatPaginationData,
    ProcessState<PaymentRequest>? createPaymentRequestState,
    int? lastUpdatedPaymentRequestId,
    int? unreadConversationsCount,
  }) {
    return ConversationsState._(
      conversationsState: conversationsState ?? this.conversationsState,
      chatMessagesState: chatMessagesState ?? this.chatMessagesState,
      chatPaginationData: chatPaginationData ?? this.chatPaginationData,
      createPaymentRequestState:
          createPaymentRequestState ?? this.createPaymentRequestState,
      lastUpdatedPaymentRequestId:
          lastUpdatedPaymentRequestId ?? this.lastUpdatedPaymentRequestId,
      unreadConversationsCount:
          unreadConversationsCount ?? this.unreadConversationsCount,
    );
  }
}
