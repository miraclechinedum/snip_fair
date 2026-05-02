import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/apointment/customer.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/stylist.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/portfolio.dart';

part 'customer_appointment.g.dart';

@JsonSerializable()
class CustomerAppointment {

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
    this.customer,
    this.distanceFromStylist,
    this.tipAmount,
    this.tippedAt,
  });

  factory CustomerAppointment.fromJson(Map<String, dynamic> json) =>
      _$CustomerAppointmentFromJson(json);
  int? id;
  @JsonKey(name: 'stylist_id')
  String? stylistId;
  @JsonKey(name: 'customer_id')
  dynamic customerId;
  @JsonKey(name: 'booking_id')
  dynamic bookingId;
  @JsonKey(name: 'portfolio_id')
  dynamic portfolioId;
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
  String? serviceNotes;
  @JsonKey(name: 'completed_at')
  dynamic completedAt;
  @JsonKey(name: 'appointment_date_time')
  DateTime? appointmentDateTime;
  Stylist? stylist;
  Portfolio? portfolio;
  Customer? customer;
  @JsonKey(name: 'distance_from_stylist')
  String? distanceFromStylist;
  @JsonKey(name: 'tip_amount')
  double? tipAmount;
  @JsonKey(name: 'tipped_at')
  DateTime? tippedAt;

  bool get hasBeenTipped => tippedAt != null;

  Map<String, dynamic> toJson() => _$CustomerAppointmentToJson(this);
}
