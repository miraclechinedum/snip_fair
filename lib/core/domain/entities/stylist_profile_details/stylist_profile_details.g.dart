// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stylist_profile_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StylistProfileDetails _$StylistProfileDetailsFromJson(
        Map<String, dynamic> json) =>
    StylistProfileDetails(
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      portfolios: (json['portfolios'] as List<dynamic>?)
          ?.map((e) => Portfolio.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      statistics: json['statistics'] == null
          ? null
          : Statistics.fromJson(json['statistics'] as Map<String, dynamic>),
      certifications: json['certifications'] as List<dynamic>?,
      profileCompleteness: json['profile_completeness'] == null
          ? null
          : ProfileCompleteness.fromJson(
              json['profile_completeness'] as Map<String, dynamic>),
      profileLink: json['profile_link'] as String?,
    );

Map<String, dynamic> _$StylistProfileDetailsToJson(
        StylistProfileDetails instance) =>
    <String, dynamic>{
      'user': instance.user,
      'portfolios': instance.portfolios,
      'services': instance.services,
      'statistics': instance.statistics,
      'certifications': instance.certifications,
      'profile_completeness': instance.profileCompleteness,
      'profile_link': instance.profileLink,
    };
