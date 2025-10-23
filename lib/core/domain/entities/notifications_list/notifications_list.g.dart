// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationsList _$NotificationsListFromJson(Map<String, dynamic> json) =>
    NotificationsList(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => NotificationDatum.fromJson(e as Map<String, dynamic>))
          .toList(),
      path: json['path'] as String?,
      perPage: (json['per_page'] as num?)?.toInt(),
      nextCursor: json['next_cursor'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      prevCursor: json['prev_cursor'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
    );

Map<String, dynamic> _$NotificationsListToJson(NotificationsList instance) =>
    <String, dynamic>{
      'data': instance.data,
      'path': instance.path,
      'per_page': instance.perPage,
      'next_cursor': instance.nextCursor,
      'next_page_url': instance.nextPageUrl,
      'prev_cursor': instance.prevCursor,
      'prev_page_url': instance.prevPageUrl,
    };
