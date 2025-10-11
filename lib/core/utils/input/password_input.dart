// ignore_for_file: sort_constructors_first

import 'package:formz/formz.dart';

enum PasswordInputValidationError {
  empty('This field cannot be empty'),
  short(
    'Password must be a least 8 characters with no spaces, include at least one letter, one number and one special character.',
  ),
  invalid(
    'Password must be a least 8 characters with no spaces, include at least one letter, one number and one special character.',
  );

  final String message;

  const PasswordInputValidationError(this.message);
}

class PasswordInput extends FormzInput<String, PasswordInputValidationError> {
  // Call super.pure to represent an unmodified form input.
  const PasswordInput.pure({this.pinLenght = 8}) : super.pure('');

  // Call super.dirty to represent a modified form input.
  const PasswordInput.dirty({this.pinLenght = 8, String value = ''})
      : super.dirty(value);

  static final _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  final int pinLenght;

  // Override validator to handle validating a given input value.
  @override
  PasswordInputValidationError? validator(String? value) {
    if (value == null) return PasswordInputValidationError.empty;
    if (value.isEmpty) return PasswordInputValidationError.empty;
    if (value.length < pinLenght) {
      return PasswordInputValidationError.short;
    }
    if (!_passwordRegExp.hasMatch(value)) {
      return PasswordInputValidationError.invalid;
    }
    return null;
  }
}
