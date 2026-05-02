import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/timeslot.dart';

part 'schedule.g.dart';

@JsonSerializable()
class Schedule {

  Schedule({
    this.id,
    this.userId,
    this.day,
    this.available,
    this.createdAt,
    this.updatedAt,
    this.slots,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return _$ScheduleFromJson(json);
  }
  int? id;
  @JsonKey(name: 'user_id')
  dynamic userId;
  String? day;
  bool? available;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  List<TimeSlot>? slots;

  Map<String, dynamic> toJson() => _$ScheduleToJson(this);
}
