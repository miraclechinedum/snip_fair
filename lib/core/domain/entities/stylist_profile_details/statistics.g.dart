// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Statistics _$StatisticsFromJson(Map<String, dynamic> json) => Statistics(
      totalWorks: json['total_works'],
      totalLikes: json['total_likes'],
      totalReviews: json['total_reviews'],
      averageRating: json['average_rating'],
      totalAppointments: json['total_appointments'],
      totalEarnings: json['total_earnings'],
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
