import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/utils/json_coercion.dart';

part 'total_withdrawn.g.dart';

@JsonSerializable()
class TotalWithdrawn {
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
  /// Money: kept as sent (cents included); null when missing or invalid.
  @JsonKey(fromJson: toNumOrNull)
  num? value;
  @JsonKey(name: 'current_period')
  dynamic currentPeriod;
  @JsonKey(name: 'change_percentage')
  dynamic changePercentage;
  @JsonKey(name: 'change_text')
  String? changeText;
  @JsonKey(name: 'is_positive')
  bool? isPositive;

  Map<String, dynamic> toJson() => _$TotalWithdrawnToJson(this);
}
