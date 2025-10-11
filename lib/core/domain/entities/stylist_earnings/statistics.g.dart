// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Statistics _$StatisticsFromJson(Map<String, dynamic> json) => Statistics(
      totalEarnings: json['total_earnings'] == null
          ? null
          : TotalEarnings.fromJson(
              json['total_earnings'] as Map<String, dynamic>),
      totalBalance: json['total_balance'] == null
          ? null
          : TotalBalance.fromJson(
              json['total_balance'] as Map<String, dynamic>),
      totalWithdrawn: json['total_withdrawn'] == null
          ? null
          : TotalWithdrawn.fromJson(
              json['total_withdrawn'] as Map<String, dynamic>),
      totalRequests: json['total_requests'] == null
          ? null
          : TotalRequests.fromJson(
              json['total_requests'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StatisticsToJson(Statistics instance) =>
    <String, dynamic>{
      'total_earnings': instance.totalEarnings,
      'total_balance': instance.totalBalance,
      'total_withdrawn': instance.totalWithdrawn,
      'total_requests': instance.totalRequests,
    };
