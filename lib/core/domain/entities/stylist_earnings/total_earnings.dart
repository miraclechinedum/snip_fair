import 'package:json_annotation/json_annotation.dart';

part 'total_earnings.g.dart';

@JsonSerializable()
class TotalEarnings {
  TotalEarnings({
    this.value,
    this.currentPeriod,
    this.changePercentage,
    this.changeText,
    this.isPositive,
  });

  factory TotalEarnings.fromJson(Map<String, dynamic> json) {
    return _$TotalEarningsFromJson(json);
  }
  int? value;
  @JsonKey(name: 'current_period')
  dynamic currentPeriod;
  @JsonKey(name: 'change_percentage')
  dynamic changePercentage;
  @JsonKey(name: 'change_text')
  dynamic changeText;
  @JsonKey(name: 'is_positive')
  bool? isPositive;

  Map<String, dynamic> toJson() => _$TotalEarningsToJson(this);
}
