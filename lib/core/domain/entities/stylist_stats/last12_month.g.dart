// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last12_month.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Last12Month _$Last12MonthFromJson(Map<String, dynamic> json) => Last12Month(
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      appointmentCount: (json['appointment_count'] as num?)?.toInt(),
      confirmedAppointmentCount:
          (json['confirmed_appointment_count'] as num?)?.toInt(),
      canceledAppointmentCount:
          (json['canceled_appointment_count'] as num?)?.toInt(),
      completedAppointmentCount:
          (json['completed_appointment_count'] as num?)?.toInt(),
      premiumAppointmentCount:
          (json['premium_appointment_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$Last12MonthToJson(Last12Month instance) =>
    <String, dynamic>{
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'appointment_count': instance.appointmentCount,
      'confirmed_appointment_count': instance.confirmedAppointmentCount,
      'canceled_appointment_count': instance.canceledAppointmentCount,
      'completed_appointment_count': instance.completedAppointmentCount,
      'premium_appointment_count': instance.premiumAppointmentCount,
    };
