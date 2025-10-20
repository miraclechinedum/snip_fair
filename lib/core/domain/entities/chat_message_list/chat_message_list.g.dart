// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageList _$ChatMessageListFromJson(Map<String, dynamic> json) =>
    ChatMessageList(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      path: json['path'] as String?,
      perPage: (json['per_page'] as num?)?.toInt(),
      nextCursor: json['next_cursor'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      prevCursor: json['prev_cursor'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
    );

Map<String, dynamic> _$ChatMessageListToJson(ChatMessageList instance) =>
    <String, dynamic>{
      'data': instance.data,
      'path': instance.path,
      'per_page': instance.perPage,
      'next_cursor': instance.nextCursor,
      'next_page_url': instance.nextPageUrl,
      'prev_cursor': instance.prevCursor,
      'prev_page_url': instance.prevPageUrl,
    };
