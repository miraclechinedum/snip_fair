import 'package:json_annotation/json_annotation.dart';

part 'escrow_item.g.dart';

@JsonSerializable()
class EscrowItem {
  EscrowItem({
    this.pouchId,
    this.appointmentId,
    this.bookingRef,
    this.service,
    this.appointmentDate,
    this.appointmentTime,
    this.heldAmount,
    this.completedAt,
    this.releaseAt,
    this.status,
    this.statusLabel,
  });

  factory EscrowItem.fromJson(Map<String, dynamic> json) =>
      _$EscrowItemFromJson(json);

  @JsonKey(name: 'pouch_id')
  int? pouchId;

  @JsonKey(name: 'appointment_id')
  int? appointmentId;

  @JsonKey(name: 'booking_ref')
  String? bookingRef;

  String? service;

  @JsonKey(name: 'appointment_date')
  String? appointmentDate;

  @JsonKey(name: 'appointment_time')
  String? appointmentTime;

  // Backend drops .0 on whole numbers (42 vs 66.5), so JSON can be int or
  // double. Parse defensively as double either way.
  @JsonKey(name: 'held_amount', fromJson: escrowToDouble)
  double? heldAmount;

  // UTC on the wire. Format with .toLocal() at the presentation layer.
  @JsonKey(name: 'completed_at')
  DateTime? completedAt;

  @JsonKey(name: 'release_at')
  DateTime? releaseAt;

  // 'held' | 'releasing_soon' | 'pending_release'
  String? status;

  // Human-readable label chosen by the backend — render as-is, don't derive
  // client-side, so backend stays the source of truth for wording.
  @JsonKey(name: 'status_label')
  String? statusLabel;

  Map<String, dynamic> toJson() => _$EscrowItemToJson(this);
}

double? escrowToDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
