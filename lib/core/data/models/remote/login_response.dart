import 'package:snip_fair/core/domain/entities/user/user.dart';

class LoginResponse {
  LoginResponse({this.token, this.role, this.user});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    token = json['token'] as String?;
    role = json['role'] as String?;
    user = json['user'] != null
        ? User.fromJson(json['user'] as Map<String, dynamic>)
        : null;
  }
  String? token;
  String? role;
  User? user;

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
