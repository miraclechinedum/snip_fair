// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalBalance _$TotalBalanceFromJson(Map<String, dynamic> json) => TotalBalance(
      value: (json['value'] as num?)?.toInt(),
      changePercentage: (json['change_percentage'] as num?)?.toInt(),
      changeText: json['change_text'] as String?,
      isPositive: json['is_positive'] as bool?,
    );

Map<String, dynamic> _$TotalBalanceToJson(TotalBalance instance) =>
    <String, dynamic>{
      'value': instance.value,
      'change_percentage': instance.changePercentage,
      'change_text': instance.changeText,
      'is_positive': instance.isPositive,
    };
