import 'package:json_annotation/json_annotation.dart';

import 'appointment.dart';
import 'customer.dart';
import 'stylist.dart';

part 'dispute.g.dart';

@JsonSerializable()
class Dispute {
  int? id;
  String? comment;
  @JsonKey(name: 'image_urls')
  List<String>? imageUrls;
  String? status;
  String? priority;
  @JsonKey(name: 'resolution_type')
  dynamic resolutionType;
  @JsonKey(name: 'resolution_amount')
  double? resolutionAmount;
  @JsonKey(name: 'resolution_comment')
  dynamic resolutionComment;
  @JsonKey(name: 'resolved_at')
  dynamic resolvedAt;
  String? from;
  @JsonKey(name: 'appointment_id')
  String? appointmentId;
  @JsonKey(name: 'ref_id')
  String? refId;
  @JsonKey(name: 'customer_id')
  String? customerId;
  @JsonKey(name: 'stylist_id')
  String? stylistId;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'resolved_by')
  dynamic resolvedBy;
  Appointment? appointment;
  Customer? customer;
  Stylist? stylist;
  List<dynamic>? messages;

  Dispute({
    this.id,
    this.comment,
    this.imageUrls,
    this.status,
    this.priority,
    this.resolutionType,
    this.resolutionAmount,
    this.resolutionComment,
    this.resolvedAt,
    this.from,
    this.appointmentId,
    this.refId,
    this.customerId,
    this.stylistId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.resolvedBy,
    this.appointment,
    this.customer,
    this.stylist,
    this.messages,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) => _$DisputeFromJson(json);

  Map<String, dynamic> toJson() => _$DisputeToJson(this);
}
