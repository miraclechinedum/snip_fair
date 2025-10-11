// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stylist_profile.freezed.dart';
part 'stylist_profile.g.dart';

@freezed
sealed class StylistProfile with _$StylistProfile {
  factory StylistProfile({
    int? id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'business_name') String? businessName,
    @JsonKey(name: 'years_of_experience') int? yearsOfExperience,
    @JsonKey(name: 'identification_id') String? identificationId,
    @JsonKey(name: 'identification_file') String? identificationFile,
    @JsonKey(name: 'visits_count') int? visitsCount,
    String? status,
    @JsonKey(name: 'is_available') bool? isAvailable,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    dynamic banner,
    dynamic socials,
    dynamic works,
  }) = _StylistProfile;

  factory StylistProfile.fromJson(Map<String, dynamic> json) =>
      _$StylistProfileFromJson(json);
}
