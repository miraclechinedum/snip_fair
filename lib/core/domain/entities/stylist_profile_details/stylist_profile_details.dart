import 'package:json_annotation/json_annotation.dart';

import 'portfolio.dart';
import 'profile_completeness.dart';
import 'statistics.dart';
import 'user.dart';

part 'stylist_profile_details.g.dart';

@JsonSerializable()
class StylistProfileDetails {
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

  factory StylistProfileDetails.fromJson(Map<String, dynamic> json) {
    return _$StylistProfileDetailsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$StylistProfileDetailsToJson(this);
}
