// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Availability _$AvailabilityFromJson(Map<String, dynamic> json) => Availability(
      availability: json['availability'] as String?,
      responseTime: json['response_time'] as String?,
      nextAvailable: json['next_available'] as String?,
    );

Map<String, dynamic> _$AvailabilityToJson(Availability instance) =>
    <String, dynamic>{
      'availability': instance.availability,
      'response_time': instance.responseTime,
      'next_available': instance.nextAvailable,
    };
