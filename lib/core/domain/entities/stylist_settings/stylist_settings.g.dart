// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stylist_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StylistSettings _$StylistSettingsFromJson(Map<String, dynamic> json) =>
    StylistSettings(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      automaticPayout: json['automatic_payout'] as bool?,
      instantPayout: json['instant_payout'] as bool?,
      payoutFrequency: json['payout_frequency'] as String?,
      payoutDay: json['payout_day'] as String?,
      enableMobileAppointments: json['enable_mobile_appointments'] as bool?,
      enableShopAppointments: json['enable_shop_appointments'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$StylistSettingsToJson(StylistSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'automatic_payout': instance.automaticPayout,
      'instant_payout': instance.instantPayout,
      'payout_frequency': instance.payoutFrequency,
      'payout_day': instance.payoutDay,
      'enable_mobile_appointments': instance.enableMobileAppointments,
      'enable_shop_appointments': instance.enableShopAppointments,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
