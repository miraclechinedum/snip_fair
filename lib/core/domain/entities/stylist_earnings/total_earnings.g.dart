// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_earnings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalEarnings _$TotalEarningsFromJson(Map<String, dynamic> json) =>
    TotalEarnings(
      value: (json['value'] as num?)?.toInt(),
      currentPeriod: json['current_period'],
      changePercentage: json['change_percentage'],
      changeText: json['change_text'],
      isPositive: json['is_positive'] as bool?,
    );

Map<String, dynamic> _$TotalEarningsToJson(TotalEarnings instance) =>
    <String, dynamic>{
      'value': instance.value,
      'current_period': instance.currentPeriod,
      'change_percentage': instance.changePercentage,
      'change_text': instance.changeText,
      'is_positive': instance.isPositive,
    };
