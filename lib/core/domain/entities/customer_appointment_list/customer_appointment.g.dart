// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerAppointment _$CustomerAppointmentFromJson(Map<String, dynamic> json) => CustomerAppointment(
      id: (json['id'] as num?)?.toInt(),
      stylistId: json['stylist_id'] as String?,
      customerId: json['customer_id'],
      bookingId: json['booking_id'],
      portfolioId: json['portfolio_id'],
      amount: (json['amount'] as num?)?.toDouble(),
      duration: json['duration'] as String?,
      extra: json['extra'],
      appointmentCode: json['appointment_code'] as String?,
      completionCode: json['completion_code'] as String?,
      status: json['status'] as String?,
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
      appointmentDate: json['appointment_date'] as String?,
      appointmentTime: json['appointment_time'] as String?,
      stylistNote: json['stylist_note'],
      serviceNotes: json['service_notes'] as String?,
      completedAt: json['completed_at'],
      appointmentDateTime: json['appointment_date_time'] == null
          ? null
          : DateTime.parse(json['appointment_date_time'] as String),
      stylist: json['stylist'] == null
          ? null
          : Stylist.fromJson(json['stylist'] as Map<String, dynamic>),
      portfolio: json['portfolio'] == null
          ? null
          : Portfolio.fromJson(json['portfolio'] as Map<String, dynamic>),
      customer: json['customer'] == null
          ? null
          : Customer.fromJson(json['customer'] as Map<String, dynamic>),
      distanceFromStylist: json['distance_from_stylist'] as String?,
      tipAmount: (json['tip_amount'] as num?)?.toDouble(),
      tippedAt: json['tipped_at'] == null ? null : DateTime.parse(json['tipped_at'] as String),
    );

Map<String, dynamic> _$CustomerAppointmentToJson(CustomerAppointment instance) => <String, dynamic>{
      'id': instance.id,
      'stylist_id': instance.stylistId,
      'customer_id': instance.customerId,
      'booking_id': instance.bookingId,
      'portfolio_id': instance.portfolioId,
      'amount': instance.amount,
      'duration': instance.duration,
      'extra': instance.extra,
      'appointment_code': instance.appointmentCode,
      'completion_code': instance.completionCode,
      'status': instance.status,
      'deleted_at': instance.deletedAt,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'appointment_date': instance.appointmentDate,
      'appointment_time': instance.appointmentTime,
      'stylist_note': instance.stylistNote,
      'service_notes': instance.serviceNotes,
      'completed_at': instance.completedAt,
      'appointment_date_time': instance.appointmentDateTime?.toIso8601String(),
      'stylist': instance.stylist,
      'portfolio': instance.portfolio,
      'customer': instance.customer,
      'distance_from_stylist': instance.distanceFromStylist,
      'tip_amount': instance.tipAmount,
      'tipped_at': instance.tippedAt?.toIso8601String(),
    };
