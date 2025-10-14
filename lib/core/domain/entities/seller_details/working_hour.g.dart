// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'working_hour.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkingHour _$WorkingHourFromJson(Map<String, dynamic> json) => WorkingHour(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      day: json['day'] as String?,
      available: json['available'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      slots: (json['slots'] as List<dynamic>?)
          ?.map((e) => Slot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkingHourToJson(WorkingHour instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'day': instance.day,
      'available': instance.available,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'slots': instance.slots,
    };
