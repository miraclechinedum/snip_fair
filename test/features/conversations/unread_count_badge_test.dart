import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';
import 'package:snip_fair/features/conversations/conversations_list/widgets/unread_count_badge.dart';

ChatConversation _conversation({
  int? unreadCount,
  List<ChatMessage>? messages,
}) {
  return ChatConversation(
    id: 7,
    initiatorId: '1',
    recipientId: '2',
    unreadCount: unreadCount,
    messages: messages,
  );
}

void main() {
  group('unreadCountFor', () {
    test('uses the server-provided unread_count', () {
      expect(unreadCountFor(_conversation(unreadCount: 4), '2'), 4);
    });

    test('renders zero (no badge) when the server says nothing is unread', () {
      expect(unreadCountFor(_conversation(unreadCount: 0), '2'), 0);
    });

    test('clamps a negative server count to zero', () {
      expect(unreadCountFor(_conversation(unreadCount: -3), '2'), 0);
    });

    test('falls back to the last inbound message when the field is absent', () {
      final conv = _conversation(
        messages: [
          ChatMessage(id: 9, senderId: '1', text: 'hey', isRead: false),
        ],
      );
      expect(unreadCountFor(conv, '2'), 1);
    });

    test('does not count the current user own unread message', () {
      final conv = _conversation(
        messages: [
          ChatMessage(id: 9, senderId: '2', text: 'hey', isRead: false),
        ],
      );
      expect(unreadCountFor(conv, '2'), 0);
    });

    test('is zero for an empty conversation with no unread_count', () {
      expect(unreadCountFor(_conversation(messages: const []), '2'), 0);
    });
  });

  group('UnreadCountBadge', () {
    testWidgets('shows the numeric count, not just a colour', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UnreadCountBadge(count: 3)),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('caps large counts at 99+', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UnreadCountBadge(count: 250)),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });
  });
}
