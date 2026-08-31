import 'package:flutter/material.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';

/// Numeric unread indicator for a conversation row.
///
/// Deliberately a *count* rather than a colour change: the original build
/// signalled unread messages only by tinting the preview text purple, which
/// is invisible to anyone who doesn't already know the convention — that was
/// the client's complaint.
class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Per-conversation unread count.
///
/// Prefers the server's `unread_count` (Laravel returns it per conversation).
/// Falls back to inferring 1 from the last message only when the field is
/// absent, so an older backend response still surfaces *something* rather
/// than nothing. Never negative.
int unreadCountFor(ChatConversation conversation, String? currentUserId) {
  final serverCount = conversation.unreadCount;
  if (serverCount != null) return serverCount < 0 ? 0 : serverCount;

  final messages = conversation.messages;
  if (messages == null || messages.isEmpty) return 0;
  final last = messages.first;
  final unreadFromOther =
      last.senderId != currentUserId && last.isRead == false;
  return unreadFromOther ? 1 : 0;
}
