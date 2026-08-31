import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message_list.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repo;
  late ConversationsCubit cubit;

  ChatMessageList unreadThread() => ChatMessageList(
        data: [
          ChatMessage(id: 3, senderId: '99', text: 'c', isRead: false),
          ChatMessage(id: 2, senderId: '99', text: 'b', isRead: false),
          ChatMessage(id: 1, senderId: '7', text: 'a', isRead: true),
        ],
      );

  setUp(() {
    repo = _MockProfileRepository();
    cubit = ConversationsCubit(repo);

    when(() => repo.getChatMessages(any()))
        .thenAnswer((_) async => ApiResult.success(data: unreadThread()));
    when(
      () => repo.markMessageAsRead(
        conversationId: any(named: 'conversationId'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer(
      (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
    );
    when(repo.getChatConversations).thenAnswer(
      (_) async => ApiResult.success(
        data: [ChatConversation(id: 11, unreadCount: 2)],
      ),
    );
    when(repo.getConversationsUnreadCount)
        .thenAnswer((_) async => const ApiResult.success(data: 0));
  });

  tearDown(() => cubit.close());

  test('marks every inbound unread message exactly once', () async {
    await cubit.fetchChatMessages('11');
    await cubit.markConversationAsRead('11', currentUserId: '7');

    // Two inbound unread messages -> two PATCHes. The message the current
    // user sent, and the already-read one, are left alone.
    verify(
      () => repo.markMessageAsRead(
        conversationId: '11',
        messageId: any(named: 'messageId'),
      ),
    ).called(2);
  });

  test('clears the badge count once the conversation is opened', () async {
    // Model the server honestly: 2 unread before the thread is opened,
    // 0 afterwards.
    var flushed = false;
    when(
      () => repo.markMessageAsRead(
        conversationId: any(named: 'conversationId'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer((_) async {
      flushed = true;
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
    when(repo.getConversationsUnreadCount)
        .thenAnswer((_) async => ApiResult.success(data: flushed ? 0 : 2));
    when(repo.getChatConversations).thenAnswer(
      (_) async => ApiResult.success(
        data: [ChatConversation(id: 11, unreadCount: flushed ? 0 : 2)],
      ),
    );

    // Seed the badge from the poll loop, as MainScreen does on resume.
    cubit.startPollingConversations();
    await Future<void>.delayed(Duration.zero);
    cubit.stopPollingConversations();
    expect(cubit.state.unreadConversationsCount, 2);

    await cubit.fetchChatMessages('11');
    await cubit.markConversationAsRead('11', currentUserId: '7');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.unreadConversationsCount, 0);
    expect(cubit.state.conversationsState.data!.single.unreadCount, 0);
  });

  test('is a no-op when there is nothing unread', () async {
    when(() => repo.getChatMessages(any())).thenAnswer(
      (_) async => ApiResult.success(
        data: ChatMessageList(
          data: [ChatMessage(id: 1, senderId: '99', isRead: true)],
        ),
      ),
    );

    await cubit.fetchChatMessages('11');
    await cubit.markConversationAsRead('11', currentUserId: '7');

    verifyNever(
      () => repo.markMessageAsRead(
        conversationId: any(named: 'conversationId'),
        messageId: any(named: 'messageId'),
      ),
    );
  });

  test('a failed first fetch does not crash the conversations list', () async {
    when(repo.getChatConversations).thenAnswer(
      (_) async => ApiResult.failure(error: RemoteException.httpError(500)),
    );

    // Regression: this used to null-assert on `conversationsState.data!`
    // before any successful fetch had populated it.
    await cubit.fetchConversations();

    expect(cubit.state.conversationsState.data, isEmpty);
  });
}
