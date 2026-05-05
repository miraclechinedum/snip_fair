import 'package:json_annotation/json_annotation.dart';

part 'statistics.g.dart';

@JsonSerializable()
class Statistics {
  Statistics({
    this.totalWorks,
    this.totalLikes,
    this.totalReviews,
    this.averageRating,
    this.totalAppointments,
    this.totalEarnings,
    this.scheduleSummary,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return _$StatisticsFromJson(json);
  }
  @JsonKey(name: 'total_works')
  dynamic totalWorks;
  @JsonKey(name: 'total_likes')
  dynamic totalLikes;
  @JsonKey(name: 'total_reviews')
  dynamic totalReviews;
  @JsonKey(name: 'average_rating')
  dynamic averageRating;
  @JsonKey(name: 'total_appointments')
  dynamic totalAppointments;
  @JsonKey(name: 'total_earnings')
  dynamic totalEarnings;
  @JsonKey(name: 'schedule_summary')
  dynamic scheduleSummary;

  Map<String, dynamic> toJson() => _$StatisticsToJson(this);
}
