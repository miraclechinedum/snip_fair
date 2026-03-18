import 'package:json_annotation/json_annotation.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/user.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/preferences.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/notifications.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile.dart';


part 'customer_profile_details.g.dart';

@JsonSerializable()
class CustomerProfileDetails {

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
  User? user;
  @JsonKey(name: 'payment_methods')
  List<dynamic>? paymentMethods;
  @JsonKey(name: 'customer_profile')
  CustomerProfile? customerProfile;
  Preferences? preferences;
  Notifications? notifications;
  @JsonKey(name: 'payment_history')
  List<dynamic>? paymentHistory;

  Map<String, dynamic> toJson() => _$CustomerProfileDetailsToJson(this);
}
