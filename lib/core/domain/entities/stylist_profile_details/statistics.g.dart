// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Statistics _$StatisticsFromJson(Map<String, dynamic> json) => Statistics(
      totalWorks: (json['total_works'] as num?)?.toInt(),
      totalLikes: (json['total_likes'] as num?)?.toInt(),
      totalReviews: (json['total_reviews'] as num?)?.toInt(),
      averageRating: (json['average_rating'] as num?)?.toInt(),
      totalAppointments: (json['total_appointments'] as num?)?.toInt(),
      totalEarnings: (json['total_earnings'] as num?)?.toInt(),
      scheduleSummary: json['schedule_summary'],
    );

Map<String, dynamic> _$StatisticsToJson(Statistics instance) =>
    <String, dynamic>{
      'total_works': instance.totalWorks,
      'total_likes': instance.totalLikes,
      'total_reviews': instance.totalReviews,
      'average_rating': instance.averageRating,
      'total_appointments': instance.totalAppointments,
      'total_earnings': instance.totalEarnings,
      'schedule_summary': instance.scheduleSummary,
    };
