// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stylist_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StylistProfile _$StylistProfileFromJson(Map<String, dynamic> json) =>
    StylistProfile(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'],
      businessName: json['business_name'] as String?,
      yearsOfExperience: (json['years_of_experience'] as num?)?.toInt(),
      identificationId: json['identification_id'] as String?,
      identificationFile: json['identification_file'] as String?,
      identificationProof: json['identification_proof'] as String?,
      visitsCount: (json['visits_count'] as num?)?.toInt(),
      status: json['status'] as String?,
      isAvailable: json['is_available'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      banner: json['banner'] as String?,
      socials: (json['socials'] as List<dynamic>?)
          ?.map((e) => Social.fromJson(e as Map<String, dynamic>))
          .toList(),
      works:
          (json['works'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$StylistProfileToJson(StylistProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'business_name': instance.businessName,
      'years_of_experience': instance.yearsOfExperience,
      'identification_id': instance.identificationId,
      'identification_file': instance.identificationFile,
      'identification_proof': instance.identificationProof,
      'visits_count': instance.visitsCount,
      'status': instance.status,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'banner': instance.banner,
      'socials': instance.socials,
      'works': instance.works,
    };
