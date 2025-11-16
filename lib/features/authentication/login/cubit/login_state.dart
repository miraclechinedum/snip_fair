part of 'login_cubit.dart';

class LoginState extends BaseState {
  LoginState._({
    required this.email,
    required this.password,
    required this.loginResult,
    required this.showPassword,
    required this.googleLoginResult,
    super.exception,
    super.isLoading,
  });

  LoginState.initial()
      : this._(
          email: const EmailInput.pure(),
          password: const StringInput.pure(),
          loginResult: const ProcessState.init(null),
          googleLoginResult: const ProcessState.init(null),
          showPassword: false,
        );

  final EmailInput email;
  final StringInput password;
  final bool showPassword;
  final ProcessState<LoginResponse> loginResult;
  final ProcessState<LoginResponse> googleLoginResult;

  bool get canLogin =>
      Formz.validate([email, password]) && !loginResult.isLoading;

  @override
  LoginState copyWith({
    EmailInput? email,
    StringInput? password,
    ProcessState<LoginResponse>? loginResult,
    ProcessState<LoginResponse>? googleLoginResult,
    bool? showPassword,
    Exception? exception,
    bool? isLoading,

  }) {
    return LoginState._(
      email: email ?? this.email,
      password: password ?? this.password,
      loginResult: loginResult ?? this.loginResult,
      googleLoginResult: googleLoginResult ?? this.googleLoginResult,
      showPassword: showPassword ?? this.showPassword,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        loginResult,
        googleLoginResult,
        showPassword,
        exception,
        isLoading,
      ];
}
