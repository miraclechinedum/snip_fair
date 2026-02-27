// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRequestUser _$PaymentRequestUserFromJson(Map<String, dynamic> json) =>
    PaymentRequestUser(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      profilePicture: json['profile_picture'] as String?,
    );

Map<String, dynamic> _$PaymentRequestUserToJson(PaymentRequestUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profile_picture': instance.profilePicture,
    };

PaymentRequestItem _$PaymentRequestItemFromJson(Map<String, dynamic> json) =>
    PaymentRequestItem(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PaymentRequestItemToJson(PaymentRequestItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'amount': instance.amount,
    };

PaymentRequest _$PaymentRequestFromJson(Map<String, dynamic> json) =>
    PaymentRequest(
      id: (json['id'] as num?)?.toInt(),
      conversationId: (json['conversation_id'] as num?)?.toInt(),
      messageId: (json['message_id'] as num?)?.toInt(),
      appointmentId: (json['appointment_id'] as num?)?.toInt(),
      requester: json['requester'] == null
          ? null
          : PaymentRequestUser.fromJson(
              json['requester'] as Map<String, dynamic>),
      payer: json['payer'] == null
          ? null
          : PaymentRequestUser.fromJson(json['payer'] as Map<String, dynamic>),
      title: json['title'] as String?,
      description: json['description'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      statusRaw: json['status'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => PaymentRequestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      canAccept: json['can_accept'] as bool?,
      canDecline: json['can_decline'] as bool?,
      canPay: json['can_pay'] as bool?,
      canCancel: json['can_cancel'] as bool?,
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
      declinedAt: json['declined_at'] == null
          ? null
          : DateTime.parse(json['declined_at'] as String),
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PaymentRequestToJson(PaymentRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'message_id': instance.messageId,
      'appointment_id': instance.appointmentId,
      'requester': instance.requester,
      'payer': instance.payer,
      'title': instance.title,
      'description': instance.description,
      'total_amount': instance.totalAmount,
      'status': instance.statusRaw,
      'items': instance.items,
      'can_accept': instance.canAccept,
      'can_decline': instance.canDecline,
      'can_pay': instance.canPay,
      'can_cancel': instance.canCancel,
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'declined_at': instance.declinedAt?.toIso8601String(),
      'paid_at': instance.paidAt?.toIso8601String(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
