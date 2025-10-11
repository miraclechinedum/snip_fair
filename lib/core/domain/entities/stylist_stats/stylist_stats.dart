import 'package:json_annotation/json_annotation.dart';

import 'last12_month.dart';
import 'today.dart';
import 'total.dart';

part 'stylist_stats.g.dart';

@JsonSerializable()
class StylistStats {
  Total? total;
  @JsonKey(name: 'average_rating')
  num? averageRating;
  Today? today;
  @JsonKey(name: 'last_12_months')
  List<Last12Month>? last12Months;

  StylistStats({
    this.total,
    this.averageRating,
    this.today,
    this.last12Months,
  });

  factory StylistStats.fromJson(Map<String, dynamic> json) {
    return _$StylistStatsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$StylistStatsToJson(this);
}
