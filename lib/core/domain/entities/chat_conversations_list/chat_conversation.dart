import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message.dart';

import 'initiator.dart';

import 'recipient.dart';

part 'chat_conversation.g.dart';

@JsonSerializable()
class ChatConversation {
  int? id;
  @JsonKey(name: 'initiator_id')
  String? initiatorId;
  @JsonKey(name: 'recipient_id')
  String? recipientId;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  List<ChatMessage>? messages;
  Initiator? initiator;
  Recipient? recipient;

  ChatConversation({
    this.id,
    this.initiatorId,
    this.recipientId,
    this.createdAt,
    this.updatedAt,
    this.messages,
    this.initiator,
    this.recipient,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return _$ChatConversationFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ChatConversationToJson(this);
}
