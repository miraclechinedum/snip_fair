part of 'forgot_password_cubit.dart';

class ForgotPasswordState extends BaseState {
  const ForgotPasswordState._({
    required this.email,
    required this.result,
    super.exception,
    super.isLoading,
  });

  const ForgotPasswordState.initial()
      : this._(
          email: const EmailInput.pure(),
          result: const ProcessState.init(null),
        );

  final EmailInput email;
  final ProcessState<SimpleResponse> result;

  bool get canSubmit => Formz.validate([email]) && !result.isLoading;

  @override
  ForgotPasswordState copyWith({
    EmailInput? email,
    ProcessState<SimpleResponse>? result,
    Exception? exception,
    bool? isLoading,
  }) {
    return ForgotPasswordState._(
      email: email ?? this.email,
      result: result ?? this.result,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        email,
        result,
        exception,
        isLoading,
      ];
}
