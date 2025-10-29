import 'package:json_annotation/json_annotation.dart';

part 'total_withdrawn.g.dart';

@JsonSerializable()
class TotalWithdrawn {
  dynamic? value;
  @JsonKey(name: 'current_period')
  dynamic? currentPeriod;
  @JsonKey(name: 'change_percentage')
  dynamic? changePercentage;
  @JsonKey(name: 'change_text')
  String? changeText;
  @JsonKey(name: 'is_positive')
  bool? isPositive;

  TotalWithdrawn({
    this.value,
    this.currentPeriod,
    this.changePercentage,
    this.changeText,
    this.isPositive,
  });

  factory TotalWithdrawn.fromJson(Map<String, dynamic> json) {
    return _$TotalWithdrawnFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TotalWithdrawnToJson(this);
}
