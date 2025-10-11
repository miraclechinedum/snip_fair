// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalRequests _$TotalRequestsFromJson(Map<String, dynamic> json) =>
    TotalRequests(
      value: (json['value'] as num?)?.toInt(),
      changeText: json['change_text'] as String?,
      isPositive: json['is_positive'] as bool?,
    );

Map<String, dynamic> _$TotalRequestsToJson(TotalRequests instance) =>
    <String, dynamic>{
      'value': instance.value,
      'change_text': instance.changeText,
      'is_positive': instance.isPositive,
    };
