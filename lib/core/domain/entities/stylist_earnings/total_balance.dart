import 'package:json_annotation/json_annotation.dart';

part 'total_balance.g.dart';

@JsonSerializable()
class TotalBalance {
  int? value;
  @JsonKey(name: 'change_percentage')
  int? changePercentage;
  @JsonKey(name: 'change_text')
  String? changeText;
  @JsonKey(name: 'is_positive')
  bool? isPositive;

  TotalBalance({
    this.value,
    this.changePercentage,
    this.changeText,
    this.isPositive,
  });

  factory TotalBalance.fromJson(Map<String, dynamic> json) {
    return _$TotalBalanceFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TotalBalanceToJson(this);
}
