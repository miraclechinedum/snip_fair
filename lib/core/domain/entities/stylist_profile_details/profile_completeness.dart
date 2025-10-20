import 'package:json_annotation/json_annotation.dart';

import 'location_service.dart';

part 'profile_completeness.g.dart';

@JsonSerializable()
class ProfileCompleteness {
  bool? portfolio;
  @JsonKey(name: 'payment_method')
  bool? paymentMethod;
  @JsonKey(name: 'status_approved')
  bool? statusApproved;
  @JsonKey(name: 'location_service')
  bool? locationService;
  bool? address;
  @JsonKey(name: 'subscription_status')
  bool? subscriptionStatus;
  @JsonKey(name: 'social_links')
  bool? socialLinks;
  bool? works;
  @JsonKey(name: 'user_avatar')
  bool? userAvatar;
  @JsonKey(name: 'user_bio')
  bool? userBio;
  @JsonKey(name: 'user_banner')
  bool? userBanner;

  ProfileCompleteness({
    this.portfolio,
    this.paymentMethod,
    this.statusApproved,
    this.locationService,
    this.address,
    this.subscriptionStatus,
    this.socialLinks,
    this.works,
    this.userAvatar,
    this.userBio,
    this.userBanner,
  });

  factory ProfileCompleteness.fromJson(Map<String, dynamic> json) {
    return _$ProfileCompletenessFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ProfileCompletenessToJson(this);
}
