import 'package:json_annotation/json_annotation.dart';

import 'total_balance.dart';
import 'total_earnings.dart';
import 'total_requests.dart';
import 'total_withdrawn.dart';

part 'statistics.g.dart';

@JsonSerializable()
class Statistics {
  @JsonKey(name: 'total_earnings')
  TotalEarnings? totalEarnings;
  @JsonKey(name: 'total_balance')
  TotalBalance? totalBalance;
  @JsonKey(name: 'total_withdrawn')
  TotalWithdrawn? totalWithdrawn;
  @JsonKey(name: 'total_requests')
  TotalRequests? totalRequests;

  Statistics({
    this.totalEarnings,
    this.totalBalance,
    this.totalWithdrawn,
    this.totalRequests,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return _$StatisticsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$StatisticsToJson(this);
}
