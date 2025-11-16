import 'package:json_annotation/json_annotation.dart';

part 'today.g.dart';

@JsonSerializable()
class Today {
  int? earnings;
  int? appointments;
  @JsonKey(name: 'pending_appointments')
  int? pendingAppointments;
  @JsonKey(name: 'active_appointments')
  int? activeAppointments;

  Today(
      {this.earnings,
      this.appointments,
      this.pendingAppointments,
      this.activeAppointments});

  factory Today.fromJson(Map<String, dynamic> json) => _$TodayFromJson(json);

  Map<String, dynamic> toJson() => _$TodayToJson(this);
}
