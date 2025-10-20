// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dispute _$DisputeFromJson(Map<String, dynamic> json) => Dispute(
      id: (json['id'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: json['status'] as String?,
      priority: json['priority'] as String?,
      resolutionType: json['resolution_type'],
      resolutionAmount: (json['resolution_amount'] as num?)?.toDouble(),
      resolutionComment: json['resolution_comment'],
      resolvedAt: json['resolved_at'],
      from: json['from'] as String?,
      appointmentId: json['appointment_id'] as String?,
      refId: json['ref_id'] as String?,
      customerId: json['customer_id'] as String?,
      stylistId: json['stylist_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'],
      resolvedBy: json['resolved_by'],
      appointment: json['appointment'] == null
          ? null
          : Appointment.fromJson(json['appointment'] as Map<String, dynamic>),
      customer: json['customer'] == null
          ? null
          : Customer.fromJson(json['customer'] as Map<String, dynamic>),
      stylist: json['stylist'] == null
          ? null
          : Stylist.fromJson(json['stylist'] as Map<String, dynamic>),
      messages: json['messages'] as List<dynamic>?,
    );

Map<String, dynamic> _$DisputeToJson(Dispute instance) => <String, dynamic>{
      'id': instance.id,
      'comment': instance.comment,
      'image_urls': instance.imageUrls,
      'status': instance.status,
      'priority': instance.priority,
      'resolution_type': instance.resolutionType,
      'resolution_amount': instance.resolutionAmount,
      'resolution_comment': instance.resolutionComment,
      'resolved_at': instance.resolvedAt,
      'from': instance.from,
      'appointment_id': instance.appointmentId,
      'ref_id': instance.refId,
      'customer_id': instance.customerId,
      'stylist_id': instance.stylistId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt,
      'resolved_by': instance.resolvedBy,
      'appointment': instance.appointment,
      'customer': instance.customer,
      'stylist': instance.stylist,
      'messages': instance.messages,
    };
