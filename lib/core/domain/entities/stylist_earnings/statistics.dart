import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/total_balance.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/total_earnings.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/total_requests.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/total_withdrawn.dart';

part 'statistics.g.dart';

@JsonSerializable()
class Statistics {
  Statistics({
    this.totalEarnings,
    this.totalBalance,
    this.totalWithdrawn,
    this.totalRequests,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return _$StatisticsFromJson(json);
  }
  @JsonKey(name: 'total_earnings')
  TotalEarnings? totalEarnings;
  @JsonKey(name: 'total_balance')
  TotalBalance? totalBalance;
  @JsonKey(name: 'total_withdrawn')
  TotalWithdrawn? totalWithdrawn;
  @JsonKey(name: 'total_requests')
  TotalRequests? totalRequests;

  Map<String, dynamic> toJson() => _$StatisticsToJson(this);
}
