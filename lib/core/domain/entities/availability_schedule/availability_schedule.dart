import 'package:json_annotation/json_annotation.dart';

import 'schedule.dart';

part 'availability_schedule.g.dart';

@JsonSerializable()
class AvailabilitySchedule {
  @JsonKey(name: 'is_available')
  bool? isAvailable;
  List<Schedule>? schedules;

  AvailabilitySchedule({this.isAvailable, this.schedules});

  factory AvailabilitySchedule.fromJson(Map<String, dynamic> json) {
    return _$AvailabilityScheduleFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AvailabilityScheduleToJson(this);
}
