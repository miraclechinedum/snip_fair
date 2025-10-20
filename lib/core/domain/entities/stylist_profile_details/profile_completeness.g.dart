// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_completeness.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileCompleteness _$ProfileCompletenessFromJson(Map<String, dynamic> json) =>
    ProfileCompleteness(
      portfolio: json['portfolio'] as bool?,
      paymentMethod: json['payment_method'] as bool?,
      statusApproved: json['status_approved'] as bool?,
      locationService: json['location_service'] as bool?,
      address: json['address'] as bool?,
      subscriptionStatus: json['subscription_status'] as bool?,
      socialLinks: json['social_links'] as bool?,
      works: json['works'] as bool?,
      userAvatar: json['user_avatar'] as bool?,
      userBio: json['user_bio'] as bool?,
      userBanner: json['user_banner'] as bool?,
    );

Map<String, dynamic> _$ProfileCompletenessToJson(
        ProfileCompleteness instance) =>
    <String, dynamic>{
      'portfolio': instance.portfolio,
      'payment_method': instance.paymentMethod,
      'status_approved': instance.statusApproved,
      'location_service': instance.locationService,
      'address': instance.address,
      'subscription_status': instance.subscriptionStatus,
      'social_links': instance.socialLinks,
      'works': instance.works,
      'user_avatar': instance.userAvatar,
      'user_bio': instance.userBio,
      'user_banner': instance.userBanner,
    };
