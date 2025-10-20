import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  ChatMessage({
    this.id,
    this.conversationId,
    this.senderId,
    this.receiverId,
    this.text,
    this.attachment,
    this.isRead,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  int? id;
  @JsonKey(name: 'conversation_id')
  String? conversationId;
  @JsonKey(name: 'sender_id')
  String? senderId;
  @JsonKey(name: 'receiver_id')
  String? receiverId;
  String? text;
  String? attachment;
  @JsonKey(name: 'is_read')
  bool? isRead;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
