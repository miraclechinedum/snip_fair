// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) =>
    PaymentMethod(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      accountNumber: json['account_number'] as String?,
      accountName: json['account_name'] as String?,
      bankName: json['bank_name'] as String?,
      routingNumber: json['routing_number'] as String?,
      isDefault: json['is_default'] as bool?,
      isActive: json['is_active'] as bool?,
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      bank: json['bank'] as String?,
      account: json['account'] as String?,
      routing: json['routing'] as String?,
    );

Map<String, dynamic> _$PaymentMethodToJson(PaymentMethod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'account_number': instance.accountNumber,
      'account_name': instance.accountName,
      'bank_name': instance.bankName,
      'routing_number': instance.routingNumber,
      'is_default': instance.isDefault,
      'is_active': instance.isActive,
      'deleted_at': instance.deletedAt,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'bank': instance.bank,
      'account': instance.account,
      'routing': instance.routing,
    };
