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
    this.type,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
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

  /// 'text' (default) or 'payment_request'
  String? type;

  /// For payment_request: {'payment_request_id': int}
  Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  bool get isPaymentRequest => type == 'payment_request';

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
