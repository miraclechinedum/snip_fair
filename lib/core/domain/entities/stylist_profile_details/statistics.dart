import 'package:json_annotation/json_annotation.dart';

part 'statistics.g.dart';

@JsonSerializable()
class Statistics {
  @JsonKey(name: 'total_works')
  int? totalWorks;
  @JsonKey(name: 'total_likes')
  int? totalLikes;
  @JsonKey(name: 'total_reviews')
  int? totalReviews;
  @JsonKey(name: 'average_rating')
  int? averageRating;
  @JsonKey(name: 'total_appointments')
  int? totalAppointments;
  @JsonKey(name: 'total_earnings')
  int? totalEarnings;
  @JsonKey(name: 'schedule_summary')
  dynamic scheduleSummary;

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

  Map<String, dynamic> toJson() => _$StatisticsToJson(this);
}
