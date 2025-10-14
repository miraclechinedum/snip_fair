import 'package:json_annotation/json_annotation.dart';

part 'availability.g.dart';

@JsonSerializable()
class Availability {
  String? availability;
  @JsonKey(name: 'response_time')
  String? responseTime;
  @JsonKey(name: 'next_available')
  String? nextAvailable;

  Availability({this.availability, this.responseTime, this.nextAvailable});

  factory Availability.fromJson(Map<String, dynamic> json) {
    return _$AvailabilityFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AvailabilityToJson(this);
}
