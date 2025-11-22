part of 'signup_cubit.dart';

class SignupState extends BaseState {
  const SignupState._({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.gender,
    required this.password,
    required this.confirmPassword,
    required this.signUpResult,
    required this.googleLoginResult,
    required this.acceptTerms,
    required this.showPassword,
    super.exception,
    super.isLoading,
  });

  const SignupState.initial()
      : this._(
          email: const EmailInput.pure(),
          gender: const StringInput.pure(),
          password: const PasswordInput.pure(),
          confirmPassword:
              const ConfirmPasswordInput.pure(PasswordInput.pure()),
          signUpResult: const ProcessState.init(null),
          firstName: const StringInput.pure(),
          lastName: const StringInput.pure(),
          phone: const PhoneInput.pure(),
          googleLoginResult: const ProcessState.init(null),
          acceptTerms: false,
          showPassword: false,
        );

  final StringInput firstName;
  final StringInput lastName;
  final StringInput gender;
  final PhoneInput phone;
  final EmailInput email;
  final PasswordInput password;
  final ConfirmPasswordInput confirmPassword;
  final ProcessState<LoginResponse> signUpResult;
  final ProcessState<LoginResponse> googleLoginResult;
  final bool acceptTerms;
  final bool showPassword;

  bool get canSignup =>
      Formz.validate([
        email,
        password,
        gender,
        firstName,
        lastName,
        phone,
        gender,
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
    StringInput? gender,
    ProcessState<LoginResponse>? signUpResult,
    ConfirmPasswordInput? confirmPassword,
    ProcessState<LoginResponse>? googleLoginResult,
    bool? acceptTerms,
    bool? showPassword,
    Exception? exception,
    bool? isLoading,
  }) {
    return SignupState._(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      password: password ?? this.password,
      googleLoginResult: googleLoginResult ?? this.googleLoginResult,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      signUpResult: signUpResult ?? this.signUpResult,
      acceptTerms: acceptTerms ?? this.acceptTerms,
      showPassword: showPassword ?? this.showPassword,
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
        gender,
        showPassword,
        googleLoginResult,
        confirmPassword,
        signUpResult,
        acceptTerms,
        exception,
        isLoading,
      ];
}
