class RegisterParams {
  RegisterParams({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.password,
    this.passwordConfirmation,
    this.deviceName,
  });

  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? password;
  String? passwordConfirmation;
  String? deviceName;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    data['phone'] = phone;
    data['password'] = password;
    data['password_confirmation'] = passwordConfirmation;
    data['device_name'] = deviceName;
    return data;
  }
}
