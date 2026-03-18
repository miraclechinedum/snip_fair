import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/today.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/total.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/last12_month.dart';

part 'stylist_stats.g.dart';

@JsonSerializable()
class StylistStats {
  StylistStats({
    this.total,
    this.averageRating,
    this.today,
    this.last12Months,
  });

  factory StylistStats.fromJson(Map<String, dynamic> json) {
    return _$StylistStatsFromJson(json);
  }
  Total? total;
  @JsonKey(name: 'average_rating')
  num? averageRating;
  Today? today;
  @JsonKey(name: 'last_12_months')
  List<Last12Month>? last12Months;

  Map<String, dynamic> toJson() => _$StylistStatsToJson(this);
}
