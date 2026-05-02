import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/dispute_list/social.dart';

part 'stylist_profile.g.dart';

@JsonSerializable()
class StylistProfile {
  StylistProfile({
    this.id,
    this.userId,
    this.businessName,
    this.yearsOfExperience,
    this.identificationId,
    this.identificationFile,
    this.identificationProof,
    this.visitsCount,
    this.status,
    this.isAvailable,
    this.createdAt,
    this.updatedAt,
    this.banner,
    this.socials,
    this.works,
  });

  factory StylistProfile.fromJson(Map<String, dynamic> json) {
    return _$StylistProfileFromJson(json);
  }
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'business_name')
  String? businessName;
  @JsonKey(name: 'years_of_experience')
  int? yearsOfExperience;
  @JsonKey(name: 'identification_id')
  String? identificationId;
  @JsonKey(name: 'identification_file')
  String? identificationFile;
  @JsonKey(name: 'identification_proof')
  dynamic identificationProof;
  @JsonKey(name: 'visits_count')
  int? visitsCount;
  String? status;
  @JsonKey(name: 'is_available')
  bool? isAvailable;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  dynamic banner;
  List<Social>? socials;
  dynamic works;

  Map<String, dynamic> toJson() => _$StylistProfileToJson(this);
}
