import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message.dart';


part 'chat_message_list.g.dart';

@JsonSerializable()
class ChatMessageList {

  ChatMessageList({
    this.data,
    this.path,
    this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory ChatMessageList.fromJson(Map<String, dynamic> json) {
    return _$ChatMessageListFromJson(json);
  }
  List<ChatMessage>? data;
  String? path;
  @JsonKey(name: 'per_page')
  int? perPage;
  @JsonKey(name: 'next_cursor')
  String? nextCursor;
  @JsonKey(name: 'next_page_url')
  String? nextPageUrl;
  @JsonKey(name: 'prev_cursor')
  String? prevCursor;
  @JsonKey(name: 'prev_page_url')
  String? prevPageUrl;

  Map<String, dynamic> toJson() => _$ChatMessageListToJson(this);
}
