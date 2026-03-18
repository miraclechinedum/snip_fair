import 'package:json_annotation/json_annotation.dart';

part 'timeslot.g.dart';

@JsonSerializable()
class TimeSlot {

  TimeSlot({
    this.from,
    this.to,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return _$TimeSlotFromJson(json);
  }
  String? from;
  String? to;

  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);

  TimeSlot copyWith({
    String? from,
    String? to,
  }) {
    return TimeSlot(
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}
