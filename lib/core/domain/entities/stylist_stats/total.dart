import 'package:json_annotation/json_annotation.dart';

part 'total.g.dart';

@JsonSerializable()
class Total {
  num? works;
  num? likes;
  num? appointments;
  @JsonKey(name: 'active_appointments')
  num? activeAppointments;
  num? earnings;

  Total(
      {this.works,
      this.likes,
      this.appointments,
      this.activeAppointments,
      this.earnings});

  factory Total.fromJson(Map<String, dynamic> json) => _$TotalFromJson(json);

  Map<String, dynamic> toJson() => _$TotalToJson(this);
}
