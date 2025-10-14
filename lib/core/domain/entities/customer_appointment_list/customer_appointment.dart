import 'package:json_annotation/json_annotation.dart';

import 'portfolio.dart';
import 'stylist.dart';

part 'customer_appointment.g.dart';

@JsonSerializable()
class CustomerAppointment {
  int? id;
  @JsonKey(name: 'stylist_id')
  int? stylistId;
  @JsonKey(name: 'customer_id')
  int? customerId;
  @JsonKey(name: 'booking_id')
  String? bookingId;
  @JsonKey(name: 'portfolio_id')
  int? portfolioId;
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
  Stylist? stylist;
  Portfolio? portfolio;
  @JsonKey(name: 'distance_from_stylist')
  String? distanceFromStylist;

  CustomerAppointment({
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
    this.stylist,
    this.portfolio,
    this.distanceFromStylist,
  });

  factory CustomerAppointment.fromJson(Map<String, dynamic> json) =>
      _$CustomerAppointmentFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerAppointmentToJson(this);
}
