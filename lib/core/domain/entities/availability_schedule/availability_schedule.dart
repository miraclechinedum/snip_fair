import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/schedule.dart';


part 'availability_schedule.g.dart';

@JsonSerializable()
class AvailabilitySchedule {

  AvailabilitySchedule({this.isAvailable, this.schedules});

  factory AvailabilitySchedule.fromJson(Map<String, dynamic> json) {
    return _$AvailabilityScheduleFromJson(json);
  }
  @JsonKey(name: 'is_available')
  bool? isAvailable;
  List<Schedule>? schedules;

  Map<String, dynamic> toJson() => _$AvailabilityScheduleToJson(this);
}
