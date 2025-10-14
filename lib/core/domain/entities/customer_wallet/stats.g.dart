// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stats _$StatsFromJson(Map<String, dynamic> json) => Stats(
      currentBalance: (json['currentBalance'] as num?)?.toInt(),
      totalTopups: (json['totalTopups'] as num?)?.toInt(),
      totalRefunds: (json['totalRefunds'] as num?)?.toInt(),
      pendingTransactions: (json['pendingTransactions'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StatsToJson(Stats instance) => <String, dynamic>{
      'currentBalance': instance.currentBalance,
      'totalTopups': instance.totalTopups,
      'totalRefunds': instance.totalRefunds,
      'pendingTransactions': instance.pendingTransactions,
    };
