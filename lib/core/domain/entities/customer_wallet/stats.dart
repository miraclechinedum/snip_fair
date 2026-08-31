import 'package:json_annotation/json_annotation.dart';

part 'stats.g.dart';

/// Reads a value under either the camelCase key or its snake_case twin.
///
/// Every other entity in this package pins an explicit snake_case
/// `@JsonKey(name: ...)`, but `Stats` never did — so the generated decoder
/// looked for `currentBalance` while the payload may well carry
/// `current_balance`, and the wallet's headline balance silently rendered
/// R0.00. Accepting both spellings makes the decode correct regardless of
/// which one Laravel emits, without needing a backend change to confirm.
Object? _camelOrSnake(Map<dynamic, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final snake = key.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '_${m[0]!.toLowerCase()}',
  );
  return json[snake];
}

@JsonSerializable()
class Stats {
  Stats({
    this.currentBalance,
    this.totalTopups,
    this.totalRefunds,
    this.pendingTransactions,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => _$StatsFromJson(json);

  // `num`, not `int` — these are money values and the backend sends cents.
  // An `int` cast truncated them (R250.50 rendered as R250.00).
  @JsonKey(readValue: _camelOrSnake)
  num? currentBalance;
  @JsonKey(readValue: _camelOrSnake)
  num? totalTopups;
  @JsonKey(readValue: _camelOrSnake)
  num? totalRefunds;
  @JsonKey(readValue: _camelOrSnake)
  int? pendingTransactions;

  Map<String, dynamic> toJson() => _$StatsToJson(this);
}
