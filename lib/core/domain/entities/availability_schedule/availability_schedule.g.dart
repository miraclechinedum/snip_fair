// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailabilitySchedule _$AvailabilityScheduleFromJson(
        Map<String, dynamic> json) =>
    AvailabilitySchedule(
      isAvailable: json['is_available'] as bool?,
      schedules: (json['schedules'] as List<dynamic>?)
          ?.map((e) => Schedule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AvailabilityScheduleToJson(
        AvailabilitySchedule instance) =>
    <String, dynamic>{
      'is_available': instance.isAvailable,
      'schedules': instance.schedules,
    };
