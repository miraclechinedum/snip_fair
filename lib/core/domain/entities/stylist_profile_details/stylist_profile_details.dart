import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/user.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/portfolio.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/statistics.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/profile_completeness.dart';

part 'stylist_profile_details.g.dart';

@JsonSerializable()
class StylistProfileDetails {
  factory StylistProfileDetails.fromJson(Map<String, dynamic> json) {
    return _$StylistProfileDetailsFromJson(json);
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
  List<String>? services;
  Statistics? statistics;
  List<dynamic>? certifications;
  @JsonKey(name: 'profile_completeness')
  ProfileCompleteness? profileCompleteness;
  @JsonKey(name: 'profile_link')
  String? profileLink;

  Map<String, dynamic> toJson() => _$StylistProfileDetailsToJson(this);
}
