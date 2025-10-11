// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      emailVerifiedAt: json['email_verified_at'] == null
          ? null
          : DateTime.parse(json['email_verified_at'] as String),
      phoneVerifiedAt: json['phone_verified_at'],
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      type: json['type'] as String?,
      role: json['role'] as String?,
      avatar: json['avatar'] as String?,
      lastLoginAt: json['last_login_at'] == null
          ? null
          : DateTime.parse(json['last_login_at'] as String),
      status: json['status'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'],
      balance: (json['balance'] as num?)?.toInt(),
      isFeatured: json['is_featured'] as bool?,
      useLocation: json['use_location'] as bool?,
      subscriptionStatus: json['subscription_status'] as String?,
      availability: json['availability'] as bool?,
      plan: json['plan'],
      stylistProfile: json['stylist_profile'] == null
          ? null
          : StylistProfile.fromJson(
              json['stylist_profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'email_verified_at': instance.emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': instance.phoneVerifiedAt,
      'phone': instance.phone,
      'country': instance.country,
      'bio': instance.bio,
      'type': instance.type,
      'role': instance.role,
      'avatar': instance.avatar,
      'last_login_at': instance.lastLoginAt?.toIso8601String(),
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt,
      'balance': instance.balance,
      'is_featured': instance.isFeatured,
      'use_location': instance.useLocation,
      'subscription_status': instance.subscriptionStatus,
      'availability': instance.availability,
      'plan': instance.plan,
      'stylist_profile': instance.stylistProfile,
    };
