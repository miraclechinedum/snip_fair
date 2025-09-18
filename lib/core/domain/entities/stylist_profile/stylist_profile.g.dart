// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stylist_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StylistProfile _$StylistProfileFromJson(Map<String, dynamic> json) =>
    _StylistProfile(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      businessName: json['business_name'] as String?,
      yearsOfExperience: (json['years_of_experience'] as num?)?.toInt(),
      identificationId: json['identification_id'] as String?,
      identificationFile: json['identification_file'] as String?,
      visitsCount: (json['visits_count'] as num?)?.toInt(),
      status: json['status'] as String?,
      isAvailable: (json['is_available'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      banner: json['banner'],
      socials: json['socials'],
      works: json['works'],
    );

Map<String, dynamic> _$StylistProfileToJson(_StylistProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'business_name': instance.businessName,
      'years_of_experience': instance.yearsOfExperience,
      'identification_id': instance.identificationId,
      'identification_file': instance.identificationFile,
      'visits_count': instance.visitsCount,
      'status': instance.status,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'banner': instance.banner,
      'socials': instance.socials,
      'works': instance.works,
    };
