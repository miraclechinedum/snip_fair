import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/utils/json_coercion.dart';

part 'pending_release.g.dart';

@JsonSerializable()
class PendingRelease {
  PendingRelease({this.value, this.changeText, this.isPositive});

  factory PendingRelease.fromJson(Map<String, dynamic> json) {
    return _$PendingReleaseFromJson(json);
  }
  /// Money: kept as sent (cents included); null when missing or invalid.
  @JsonKey(fromJson: toNumOrNull)
  num? value;
  @JsonKey(name: 'change_text')
  String? changeText;
  @JsonKey(name: 'is_positive')
  bool? isPositive;

  Map<String, dynamic> toJson() => _$PendingReleaseToJson(this);
}
