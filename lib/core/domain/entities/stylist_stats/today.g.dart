// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Today _$TodayFromJson(Map<String, dynamic> json) => Today(
      earnings: (json['earnings'] as num?)?.toInt(),
      appointments: (json['appointments'] as num?)?.toInt(),
      pendingAppointments: (json['pending_appointments'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TodayToJson(Today instance) => <String, dynamic>{
      'earnings': instance.earnings,
      'appointments': instance.appointments,
      'pending_appointments': instance.pendingAppointments,
    };
