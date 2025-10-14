import 'package:json_annotation/json_annotation.dart';

part 'customer_stats.g.dart';

@JsonSerializable()
class CustomerStats {
  @JsonKey(name: 'total_spendings')
  int? totalSpendings;
  @JsonKey(name: 'total_appointments')
  int? totalAppointments;
  @JsonKey(name: 'completed_appointments')
  int? completedAppointments;
  @JsonKey(name: 'failed_appointments')
  int? failedAppointments;
  @JsonKey(name: 'active_appointments')
  int? activeAppointments;

  CustomerStats({
    this.totalSpendings,
    this.totalAppointments,
    this.completedAppointments,
    this.failedAppointments,
    this.activeAppointments,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return _$CustomerStatsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CustomerStatsToJson(this);
}
