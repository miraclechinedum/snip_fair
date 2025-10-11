// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkList _$WorkListFromJson(Map<String, dynamic> json) => WorkList(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => WorkItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      path: json['path'] as String?,
      perPage: (json['per_page'] as num?)?.toInt(),
      nextCursor: json['next_cursor'],
      nextPageUrl: json['next_page_url'],
      prevCursor: json['prev_cursor'],
      prevPageUrl: json['prev_page_url'],
    );

Map<String, dynamic> _$WorkListToJson(WorkList instance) => <String, dynamic>{
      'data': instance.data,
      'path': instance.path,
      'per_page': instance.perPage,
      'next_cursor': instance.nextCursor,
      'next_page_url': instance.nextPageUrl,
      'prev_cursor': instance.prevCursor,
      'prev_page_url': instance.prevPageUrl,
    };
