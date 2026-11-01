// ignore_for_file: sort_constructors_first

import 'package:formz/formz.dart';

enum EmailInputValidationError {
  empty('This field cannot be empty'),
  invalid('Please enter a valid email');

  final String message;

  const EmailInputValidationError(this.message);
}

class EmailInput extends FormzInput<String, EmailInputValidationError> {
  // Call super.pure to represent an unmodified form input.
  const EmailInput.pure() : super.pure('');

  // Call super.dirty to represent a modified form input.
  const EmailInput.dirty([super.value = '']) : super.dirty();

  /// The form the backend stores and compares emails in: trimmed and
  /// lowercase, so `Miracle@Example.com` and `miracle@example.com` are the
  /// same account. Laravel normalises too; this keeps requests consistent.
  static String normalize(String value) => value.trim().toLowerCase();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  // Override validator to handle validating a given input value.
  @override
  EmailInputValidationError? validator(String? value) {
    if (value == null) return EmailInputValidationError.empty;
    if (value.isEmpty) return EmailInputValidationError.empty;
    if (!_emailRegExp.hasMatch(value)) {
      return EmailInputValidationError.invalid;
    }
    return null;
  }
}
