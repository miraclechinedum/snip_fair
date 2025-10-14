// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Preferences _$PreferencesFromJson(Map<String, dynamic> json) => Preferences(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      preferredTime: json['preferred_time'] as String?,
      preferredStylist: json['preferred_stylist'] as String?,
      autoRebooking: json['auto_rebooking'] as bool?,
      enableMobileAppointment: json['enable_mobile_appointment'] as bool?,
      emailReminders: json['email_reminders'] as bool?,
      smsReminders: json['sms_reminders'] as bool?,
      phoneReminders: json['phone_reminders'] as bool?,
      language: json['language'] as String?,
      currency: json['currency'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      useLocation: json['use_location'] as bool?,
    );

Map<String, dynamic> _$PreferencesToJson(Preferences instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'preferred_time': instance.preferredTime,
      'preferred_stylist': instance.preferredStylist,
      'auto_rebooking': instance.autoRebooking,
      'enable_mobile_appointment': instance.enableMobileAppointment,
      'email_reminders': instance.emailReminders,
      'sms_reminders': instance.smsReminders,
      'phone_reminders': instance.phoneReminders,
      'language': instance.language,
      'currency': instance.currency,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'use_location': instance.useLocation,
    };
