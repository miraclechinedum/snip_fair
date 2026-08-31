// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'escrow_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EscrowItem _$EscrowItemFromJson(Map<String, dynamic> json) => EscrowItem(
      pouchId: (json['pouch_id'] as num?)?.toInt(),
      appointmentId: (json['appointment_id'] as num?)?.toInt(),
      bookingRef: json['booking_ref'] as String?,
      service: json['service'] as String?,
      appointmentDate: json['appointment_date'] as String?,
      appointmentTime: json['appointment_time'] as String?,
      heldAmount: escrowToDouble(json['held_amount']),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      releaseAt: json['release_at'] == null
          ? null
          : DateTime.parse(json['release_at'] as String),
      status: json['status'] as String?,
      statusLabel: json['status_label'] as String?,
    );

Map<String, dynamic> _$EscrowItemToJson(EscrowItem instance) =>
    <String, dynamic>{
      'pouch_id': instance.pouchId,
      'appointment_id': instance.appointmentId,
      'booking_ref': instance.bookingRef,
      'service': instance.service,
      'appointment_date': instance.appointmentDate,
      'appointment_time': instance.appointmentTime,
      'held_amount': instance.heldAmount,
      'completed_at': instance.completedAt?.toIso8601String(),
      'release_at': instance.releaseAt?.toIso8601String(),
      'status': instance.status,
      'status_label': instance.statusLabel,
    };
