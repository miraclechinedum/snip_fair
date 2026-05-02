import 'package:json_annotation/json_annotation.dart';

part 'availability.g.dart';

@JsonSerializable()
class Availability {
  Availability({this.availability, this.responseTime, this.nextAvailable});

  factory Availability.fromJson(Map<String, dynamic> json) {
    return _$AvailabilityFromJson(json);
  }
  String? availability;
  @JsonKey(name: 'response_time')
  String? responseTime;
  @JsonKey(name: 'next_available')
  String? nextAvailable;

  Map<String, dynamic> toJson() => _$AvailabilityToJson(this);
}
