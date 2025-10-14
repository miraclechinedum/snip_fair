import 'package:json_annotation/json_annotation.dart';

import 'customer_profile.dart';
import 'notifications.dart';
import 'preferences.dart';
import 'user.dart';

part 'customer_profile_details.g.dart';

@JsonSerializable()
class CustomerProfileDetails {
  User? user;
  @JsonKey(name: 'payment_methods')
  List<dynamic>? paymentMethods;
  @JsonKey(name: 'customer_profile')
  CustomerProfile? customerProfile;
  Preferences? preferences;
  Notifications? notifications;
  @JsonKey(name: 'payment_history')
  List<dynamic>? paymentHistory;

  CustomerProfileDetails({
    this.user,
    this.paymentMethods,
    this.customerProfile,
    this.preferences,
    this.notifications,
    this.paymentHistory,
  });

  factory CustomerProfileDetails.fromJson(Map<String, dynamic> json) {
    return _$CustomerProfileDetailsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CustomerProfileDetailsToJson(this);
}
