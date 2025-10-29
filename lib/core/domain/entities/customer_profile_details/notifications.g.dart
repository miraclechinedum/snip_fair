// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notifications _$NotificationsFromJson(Map<String, dynamic> json) =>
    Notifications(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'],
      bookingConfirmation: json['booking_confirmation'] as bool?,
      appointmentReminders: json['appointment_reminders'] as bool?,
      favoriteStylistUpdate: json['favorite_stylist_update'] as bool?,
      promotionsOffers: json['promotions_offers'] as bool?,
      reviewReminders: json['review_reminders'] as bool?,
      paymentConfirmations: json['payment_confirmations'] as bool?,
      emailNotifications: json['email_notifications'] as bool?,
      pushNotifications: json['push_notifications'] as bool?,
      smsNotifications: json['sms_notifications'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$NotificationsToJson(Notifications instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'booking_confirmation': instance.bookingConfirmation,
      'appointment_reminders': instance.appointmentReminders,
      'favorite_stylist_update': instance.favoriteStylistUpdate,
      'promotions_offers': instance.promotionsOffers,
      'review_reminders': instance.reviewReminders,
      'payment_confirmations': instance.paymentConfirmations,
      'email_notifications': instance.emailNotifications,
      'push_notifications': instance.pushNotifications,
      'sms_notifications': instance.smsNotifications,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
