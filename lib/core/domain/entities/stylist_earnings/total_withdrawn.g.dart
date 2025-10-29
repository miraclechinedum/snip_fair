// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_withdrawn.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalWithdrawn _$TotalWithdrawnFromJson(Map<String, dynamic> json) =>
    TotalWithdrawn(
      value: json['value'],
      currentPeriod: json['current_period'],
      changePercentage: json['change_percentage'],
      changeText: json['change_text'] as String?,
      isPositive: json['is_positive'] as bool?,
    );

Map<String, dynamic> _$TotalWithdrawnToJson(TotalWithdrawn instance) =>
    <String, dynamic>{
      'value': instance.value,
      'current_period': instance.currentPeriod,
      'change_percentage': instance.changePercentage,
      'change_text': instance.changeText,
      'is_positive': instance.isPositive,
    };
