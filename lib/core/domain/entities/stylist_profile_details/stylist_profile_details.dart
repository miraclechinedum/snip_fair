import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/user.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/portfolio.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/statistics.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/profile_completeness.dart';
import 'package:snip_fair/core/utils/json_coercion.dart';
import 'package:snip_fair/core/domain/entities/stylist_account/stylist_account_status.dart';

part 'stylist_profile_details.g.dart';

@JsonSerializable()
class StylistProfileDetails {
  factory StylistProfileDetails.fromJson(Map<String, dynamic> json) {
    return _$StylistProfileDetailsFromJson(json)
      ..stylistAccount =
          StylistAccountStatus.tryParse(json['stylist_account']);
  }
  StylistProfileDetails({
    this.user,
    this.portfolios,
    this.services,
    this.statistics,
    this.certifications,
    this.profileCompleteness,
    this.profileLink,
  });
  User? user;
  List<Portfolio>? portfolios;
  @JsonKey(fromJson: nonNullStringList)
  List<String>? services;
  Statistics? statistics;
  List<dynamic>? certifications;
  @JsonKey(name: 'profile_completeness')
  ProfileCompleteness? profileCompleteness;
  @JsonKey(name: 'profile_link')
  String? profileLink;

  /// The backend's activation verdict (`stylist_account`), parsed by hand in
  /// [StylistProfileDetails.fromJson].
  @JsonKey(includeFromJson: false, includeToJson: false)
  StylistAccountStatus? stylistAccount;

  Map<String, dynamic> toJson() => _$StylistProfileDetailsToJson(this);
}
