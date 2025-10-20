import 'package:json_annotation/json_annotation.dart';

import 'chat_message.dart';

part 'chat_message_list.g.dart';

@JsonSerializable()
class ChatMessageList {
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

  Map<String, dynamic> toJson() => _$ChatMessageListToJson(this);
}
