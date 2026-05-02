import 'package:json_annotation/json_annotation.dart';

part 'total_requests.g.dart';

@JsonSerializable()
class TotalRequests {

  TotalRequests({this.value, this.changeText, this.isPositive});

  factory TotalRequests.fromJson(Map<String, dynamic> json) {
    return _$TotalRequestsFromJson(json);
  }
  int? value;
  @JsonKey(name: 'change_text')
  String? changeText;
  @JsonKey(name: 'is_positive')
  bool? isPositive;

  Map<String, dynamic> toJson() => _$TotalRequestsToJson(this);
}
