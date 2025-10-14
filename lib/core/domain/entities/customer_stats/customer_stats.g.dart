// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerStats _$CustomerStatsFromJson(Map<String, dynamic> json) =>
    CustomerStats(
      totalSpendings: (json['total_spendings'] as num?)?.toInt(),
      totalAppointments: (json['total_appointments'] as num?)?.toInt(),
      completedAppointments: (json['completed_appointments'] as num?)?.toInt(),
      failedAppointments: (json['failed_appointments'] as num?)?.toInt(),
      activeAppointments: (json['active_appointments'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CustomerStatsToJson(CustomerStats instance) =>
    <String, dynamic>{
      'total_spendings': instance.totalSpendings,
      'total_appointments': instance.totalAppointments,
      'completed_appointments': instance.completedAppointments,
      'failed_appointments': instance.failedAppointments,
      'active_appointments': instance.activeAppointments,
    };
