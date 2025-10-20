part of 'conversations_cubit.dart';

class ConversationsState extends Equatable {
  factory ConversationsState.initial() {
    return const ConversationsState._(
      conversationsState: ProcessState.init(null),
      chatMessagesState: ProcessState.init(null),
      chatPaginationData: PaginationData(),
    );
  }

  const ConversationsState._({
    required this.conversationsState,
    required this.chatMessagesState,
    required this.chatPaginationData,
  });

  final ProcessState<List<ChatConversation>> conversationsState;
  final ProcessState<List<ChatMessage>> chatMessagesState;
  final PaginationData chatPaginationData;

  @override
  List<Object?> get props =>
      [conversationsState, chatMessagesState, chatPaginationData];

  ConversationsState copyWith({
    ProcessState<List<ChatConversation>>? conversationsState,
    ProcessState<List<ChatMessage>>? chatMessagesState,
    PaginationData? chatPaginationData,
  }) {
    return ConversationsState._(
      conversationsState: conversationsState ?? this.conversationsState,
      chatMessagesState: chatMessagesState ?? this.chatMessagesState,
      chatPaginationData: chatPaginationData ?? this.chatPaginationData,
    );
  }
}
