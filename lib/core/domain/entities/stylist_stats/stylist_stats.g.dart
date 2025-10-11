// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stylist_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StylistStats _$StylistStatsFromJson(Map<String, dynamic> json) => StylistStats(
      total: json['total'] == null
          ? null
          : Total.fromJson(json['total'] as Map<String, dynamic>),
      averageRating: json['average_rating'] as num?,
      today: json['today'] == null
          ? null
          : Today.fromJson(json['today'] as Map<String, dynamic>),
      last12Months: (json['last_12_months'] as List<dynamic>?)
          ?.map((e) => Last12Month.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StylistStatsToJson(StylistStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'average_rating': instance.averageRating,
      'today': instance.today,
      'last_12_months': instance.last12Months,
    };
