// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerProfile _$CustomerProfileFromJson(Map<String, dynamic> json) =>
    CustomerProfile(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      billingName: json['billing_name'] as String?,
      billingEmail: json['billing_email'] as String?,
      billingCity: json['billing_city'],
      billingZip: json['billing_zip'],
      billingLocation: json['billing_location'],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CustomerProfileToJson(CustomerProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'billing_name': instance.billingName,
      'billing_email': instance.billingEmail,
      'billing_city': instance.billingCity,
      'billing_zip': instance.billingZip,
      'billing_location': instance.billingLocation,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
