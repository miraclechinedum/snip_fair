// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Total _$TotalFromJson(Map<String, dynamic> json) => Total(
      works: json['works'] as num?,
      likes: json['likes'] as num?,
      appointments: json['appointments'] as num?,
      activeAppointments: json['active_appointments'] as num?,
      earnings: json['earnings'] as num?,
    );

Map<String, dynamic> _$TotalToJson(Total instance) => <String, dynamic>{
      'works': instance.works,
      'likes': instance.likes,
      'appointments': instance.appointments,
      'active_appointments': instance.activeAppointments,
      'earnings': instance.earnings,
    };
