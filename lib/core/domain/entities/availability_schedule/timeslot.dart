import 'package:json_annotation/json_annotation.dart';

part 'timeslot.g.dart';

@JsonSerializable()
class TimeSlot {
  String? from;
  String? to;

  TimeSlot({
    this.from,
    this.to,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return _$TimeSlotFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);
}
