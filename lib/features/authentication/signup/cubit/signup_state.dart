part of 'signup_cubit.dart';

class SignupState extends BaseState {
  const SignupState._({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.signUpResult,
    required this.acceptTerms,
    super.exception,
    super.isLoading,
  });

  const SignupState.initial()
      : this._(
          email: const EmailInput.pure(),
          password: const PasswordInput.pure(),
          confirmPassword:
              const ConfirmPasswordInput.pure(PasswordInput.pure()),
          signUpResult: const ProcessState.init(null),
          firstName: const StringInput.pure(),
          lastName: const StringInput.pure(),
          phone: const PhoneInput.pure(),
          acceptTerms: false,
        );

  final StringInput firstName;
  final StringInput lastName;
  final PhoneInput phone;
  final EmailInput email;
  final PasswordInput password;
  final ConfirmPasswordInput confirmPassword;
  final ProcessState<LoginResponse> signUpResult;
  final bool acceptTerms;

  bool get canSignup =>
      Formz.validate([
        email,
        password,
        firstName,
        lastName,
        phone,
        confirmPassword,
      ]) &&
      acceptTerms &&
      !signUpResult.isLoading;

  @override
  SignupState copyWith({
    StringInput? firstName,
    StringInput? lastName,
    PhoneInput? phone,
    EmailInput? email,
    PasswordInput? password,
    ProcessState<LoginResponse>? signUpResult,
    ConfirmPasswordInput? confirmPassword,
    bool? acceptTerms,
    Exception? exception,
    bool? isLoading,
  }) {
    return SignupState._(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      signUpResult: signUpResult ?? this.signUpResult,
      acceptTerms: acceptTerms ?? this.acceptTerms,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phone,
        email,
        password,
        confirmPassword,
        signUpResult,
        acceptTerms,
        exception,
        isLoading,
      ];
}
