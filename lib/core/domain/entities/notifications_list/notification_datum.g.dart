// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_datum.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationDatum _$NotificationDatumFromJson(Map<String, dynamic> json) =>
    NotificationDatum(
      id: (json['id'] as num?)?.toInt(),
      type: json['type'] as String?,
      typeIdentifier: json['type_identifier']?.toString(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      priority: json['priority'] as String?,
      isRead: json['is_read'] as bool?,
    );

Map<String, dynamic> _$NotificationDatumToJson(NotificationDatum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'type_identifier': instance.typeIdentifier,
      'title': instance.title,
      'description': instance.description,
      'created_at': instance.createdAt?.toIso8601String(),
      'priority': instance.priority,
      'is_read': instance.isRead,
    };
