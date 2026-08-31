import 'package:json_annotation/json_annotation.dart';

part 'pending_release.g.dart';

@JsonSerializable()
class PendingRelease {
  PendingRelease({this.value, this.changeText, this.isPositive});

  factory PendingRelease.fromJson(Map<String, dynamic> json) {
    return _$PendingReleaseFromJson(json);
  }
  int? value;
  @JsonKey(name: 'change_text')
  String? changeText;
  @JsonKey(name: 'is_positive')
  bool? isPositive;

  Map<String, dynamic> toJson() => _$PendingReleaseToJson(this);
}
