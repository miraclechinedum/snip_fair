part of 'login_cubit.dart';

class LoginState extends BaseState {
  LoginState._({
    required this.email,
    required this.password,
    required this.loginResult,
    super.exception,
    super.isLoading,
  });

  LoginState.initial()
      : this._(
          email: const EmailInput.pure(),
          password: const PasswordInput.pure(),
          loginResult: const ProcessState.init(null),
        );

  final EmailInput email;
  final PasswordInput password;
  final ProcessState<LoginResponse> loginResult;

  bool get canLogin =>
      Formz.validate([email, password]) && !loginResult.isLoading;

  @override
  LoginState copyWith({
    EmailInput? email,
    PasswordInput? password,
    ProcessState<LoginResponse>? loginResult,
    Exception? exception,
    bool? isLoading,
  }) {
    return LoginState._(
      email: email ?? this.email,
      password: password ?? this.password,
      loginResult: loginResult ?? this.loginResult,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        loginResult,
        exception,
        isLoading,
      ];
}
