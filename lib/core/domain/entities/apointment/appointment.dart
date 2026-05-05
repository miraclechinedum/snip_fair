import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/apointment/proof.dart';
import 'package:snip_fair/core/domain/entities/apointment/stylist.dart';
import 'package:snip_fair/core/domain/entities/apointment/customer.dart';
import 'package:snip_fair/core/domain/entities/apointment/portfolio.dart';


part 'appointment.g.dart';

@JsonSerializable()
class StylistAppointment {

  StylistAppointment({
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
    this.customer,
    this.stylist,
    this.portfolio,
    this.proof,
    this.disputes,
  });

  factory StylistAppointment.fromJson(Map<String, dynamic> json) {
    return _$StylistAppointmentFromJson(json);
  }
  int? id;
  @JsonKey(name: 'stylist_id')
  dynamic stylistId;
  @JsonKey(name: 'customer_id')
  dynamic customerId;
  @JsonKey(name: 'booking_id')
  dynamic bookingId;
  @JsonKey(name: 'portfolio_id')
  dynamic portfolioId;
  int? amount;
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
  String? serviceNotes;
  @JsonKey(name: 'completed_at')
  dynamic completedAt;
  @JsonKey(name: 'appointment_date_time')
  DateTime? appointmentDateTime;
  Customer? customer;
  Stylist? stylist;
  Portfolio? portfolio;
  Proof? proof;
  List<dynamic>? disputes;

  Map<String, dynamic> toJson() => _$StylistAppointmentToJson(this);
}
