import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/domain/entities/stylist_account/stylist_account_status.dart';

class LoginResponse {
  LoginResponse({this.token, this.role, this.user, this.stylistAccount});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    token = json['token'] as String?;
    role = json['role'] as String?;
    user = json['user'] != null
        ? User.fromJson(json['user'] as Map<String, dynamic>)
        : null;
    // Stylists only (login and stylist registration). `GET /user` never
    // carries it, so this is the activation status right after sign-in.
    stylistAccount = StylistAccountStatus.tryParse(json['stylist_account']);
  }
  String? token;
  String? role;
  User? user;
  StylistAccountStatus? stylistAccount;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['token'] = token;
    data['role'] = role;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}
