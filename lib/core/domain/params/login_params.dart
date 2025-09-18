class LoginParams {
  LoginParams({this.email, this.password, this.deviceName});
  String? email;
  String? password;
  String? deviceName;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['email'] = email;
    data['password'] = password;
    data['device_name'] = deviceName;
    return data;
  }
}
