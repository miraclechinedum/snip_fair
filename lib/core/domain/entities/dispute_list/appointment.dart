import 'package:json_annotation/json_annotation.dart';

import 'portfolio.dart';

part 'appointment.g.dart';

@JsonSerializable()
class Appointment {
  int? id;
  @JsonKey(name: 'stylist_id')
  String? stylistId;
  @JsonKey(name: 'customer_id')
  String? customerId;
  @JsonKey(name: 'booking_id')
  String? bookingId;
  @JsonKey(name: 'portfolio_id')
  String? portfolioId;
  double? amount;
  String? duration;
  dynamic extra;
  @JsonKey(name: 'appointment_code')
  String? appointmentCode;
  @JsonKey(name: 'completion_code')
  String? completionCode;
  String? status;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  @JsonKey(name: 'appointment_date')
  String? appointmentDate;
  @JsonKey(name: 'appointment_time')
  String? appointmentTime;
  @JsonKey(name: 'stylist_note')
  dynamic stylistNote;
  @JsonKey(name: 'service_notes')
  dynamic serviceNotes;
  @JsonKey(name: 'completed_at')
  dynamic completedAt;
  @JsonKey(name: 'appointment_date_time')
  DateTime? appointmentDateTime;
  Portfolio? portfolio;

  Appointment({
    this.id,
    this.stylistId,
    this.customerId,
    this.bookingId,
    this.portfolioId,
    this.amount,
    this.duration,
    this.extra,
    this.appointmentCode,
    this.completionCode,
    this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.appointmentDate,
    this.appointmentTime,
    this.stylistNote,
    this.serviceNotes,
    this.completedAt,
    this.appointmentDateTime,
    this.portfolio,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return _$AppointmentFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AppointmentToJson(this);
}
