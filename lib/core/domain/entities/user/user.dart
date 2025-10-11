import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile/stylist_profile.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
sealed class User with _$User {
  const factory User({
    int? id,
    String? name,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    String? email,
    @JsonKey(name: 'email_verified_at') DateTime? emailVerifiedAt,
    @JsonKey(name: 'phone_verified_at') dynamic phoneVerifiedAt,
    String? phone,
    String? country,
    String? bio,
    String? type,
    String? role,
    String? avatar,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
    String? status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') dynamic deletedAt,
    int? balance,
    @JsonKey(name: 'is_featured') bool? isFeatured,
    @JsonKey(name: 'use_location') bool? useLocation,
    @JsonKey(name: 'subscription_status') String? subscriptionStatus,
    bool? availability,
    dynamic plan,
    @JsonKey(name: 'stylist_profile') StylistProfile? stylistProfile,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
