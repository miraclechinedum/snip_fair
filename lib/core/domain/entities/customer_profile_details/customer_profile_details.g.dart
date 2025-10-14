// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_profile_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerProfileDetails _$CustomerProfileDetailsFromJson(
        Map<String, dynamic> json) =>
    CustomerProfileDetails(
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      paymentMethods: json['payment_methods'] as List<dynamic>?,
      customerProfile: json['customer_profile'] == null
          ? null
          : CustomerProfile.fromJson(
              json['customer_profile'] as Map<String, dynamic>),
      preferences: json['preferences'] == null
          ? null
          : Preferences.fromJson(json['preferences'] as Map<String, dynamic>),
      notifications: json['notifications'] == null
          ? null
          : Notifications.fromJson(
              json['notifications'] as Map<String, dynamic>),
      paymentHistory: json['payment_history'] as List<dynamic>?,
    );

Map<String, dynamic> _$CustomerProfileDetailsToJson(
        CustomerProfileDetails instance) =>
    <String, dynamic>{
      'user': instance.user,
      'payment_methods': instance.paymentMethods,
      'customer_profile': instance.customerProfile,
      'preferences': instance.preferences,
      'notifications': instance.notifications,
      'payment_history': instance.paymentHistory,
    };
