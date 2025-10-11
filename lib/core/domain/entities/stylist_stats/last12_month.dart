import 'package:json_annotation/json_annotation.dart';

part 'last12_month.g.dart';

@JsonSerializable()
class Last12Month {
  @JsonKey(name: 'start_date')
  DateTime? startDate;
  @JsonKey(name: 'end_date')
  DateTime? endDate;
  @JsonKey(name: 'appointment_count')
  int? appointmentCount;
  @JsonKey(name: 'confirmed_appointment_count')
  int? confirmedAppointmentCount;
  @JsonKey(name: 'canceled_appointment_count')
  int? canceledAppointmentCount;
  @JsonKey(name: 'completed_appointment_count')
  int? completedAppointmentCount;
  @JsonKey(name: 'premium_appointment_count')
  int? premiumAppointmentCount;

  Last12Month({
    this.startDate,
    this.endDate,
    this.appointmentCount,
    this.confirmedAppointmentCount,
    this.canceledAppointmentCount,
    this.completedAppointmentCount,
    this.premiumAppointmentCount,
  });

  factory Last12Month.fromJson(Map<String, dynamic> json) {
    return _$Last12MonthFromJson(json);
  }

  Map<String, dynamic> toJson() => _$Last12MonthToJson(this);
}
