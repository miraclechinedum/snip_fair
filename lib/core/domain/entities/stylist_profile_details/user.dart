import 'package:json_annotation/json_annotation.dart';

import 'location_service.dart';
import 'stylist_profile.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  int? id;
  String? name;
  @JsonKey(name: 'first_name')
  String? firstName;
  @JsonKey(name: 'last_name')
  String? lastName;
  String? email;
  @JsonKey(name: 'email_verified_at')
  DateTime? emailVerifiedAt;
  @JsonKey(name: 'phone_verified_at')
  dynamic phoneVerifiedAt;
  String? phone;
  String? gender;
  String? country;
  String? bio;
  String? type;
  String? role;
  String? avatar;
  @JsonKey(name: 'last_login_at')
  DateTime? lastLoginAt;
  String? status;
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  int? balance;
  @JsonKey(name: 'is_featured')
  bool? isFeatured;
  @JsonKey(name: 'use_location')
  bool? useLocation;
  @JsonKey(name: 'subscription_status')
  String? subscriptionStatus;
  bool? availability;
  String? plan;
  @JsonKey(name: 'stylist_profile')
  StylistProfile? stylistProfile;
  @JsonKey(name: 'location_service')
  LocationService? locationService;

  User({
    this.id,
    this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.phone,
    this.country,
    this.bio,
    this.type,
    this.role,
    this.avatar,
    this.gender,
    this.lastLoginAt,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.balance,
    this.isFeatured,
    this.useLocation,
    this.subscriptionStatus,
    this.availability,
    this.plan,
    this.stylistProfile,
    this.locationService,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
