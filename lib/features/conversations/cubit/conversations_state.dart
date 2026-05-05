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
  });

  final ProcessState<List<ChatConversation>> conversationsState;
  final ProcessState<List<ChatMessage>> chatMessagesState;
  final PaginationData chatPaginationData;
  final ProcessState<PaymentRequest> createPaymentRequestState;

  @override
  List<Object?> get props =>
      [conversationsState, chatMessagesState, chatPaginationData, createPaymentRequestState];

  ConversationsState copyWith({
    ProcessState<List<ChatConversation>>? conversationsState,
    ProcessState<List<ChatMessage>>? chatMessagesState,
    PaginationData? chatPaginationData,
    ProcessState<PaymentRequest>? createPaymentRequestState,
  }) {
    return ConversationsState._(
      conversationsState: conversationsState ?? this.conversationsState,
      chatMessagesState: chatMessagesState ?? this.chatMessagesState,
      chatPaginationData: chatPaginationData ?? this.chatPaginationData,
      createPaymentRequestState: createPaymentRequestState ?? this.createPaymentRequestState,
    );
  }
}
