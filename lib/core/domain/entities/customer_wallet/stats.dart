import 'package:json_annotation/json_annotation.dart';

part 'stats.g.dart';

@JsonSerializable()
class Stats {
  int? currentBalance;
  int? totalTopups;
  int? totalRefunds;
  int? pendingTransactions;

  Stats({
    this.currentBalance,
    this.totalTopups,
    this.totalRefunds,
    this.pendingTransactions,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => _$StatsFromJson(json);

  Map<String, dynamic> toJson() => _$StatsToJson(this);
}
