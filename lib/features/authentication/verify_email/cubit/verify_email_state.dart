part of 'verify_email_cubit.dart';

class VerifyEmailState extends BaseState {
  const VerifyEmailState._({
    required this.otp,
    required this.result,
    super.exception,
    super.isLoading,
  });

  const VerifyEmailState.initial()
      : this._(
          otp: const OtpInput.pure(),
          result: const ProcessState.init(null),
        );

  final OtpInput otp;
  final ProcessState<SimpleResponse> result;

  bool get canSubmit => Formz.validate([otp]) && !result.isLoading;

  @override
  VerifyEmailState copyWith({
    OtpInput? otp,
    ProcessState<SimpleResponse>? result,
    Exception? exception,
    bool? isLoading,
  }) {
    return VerifyEmailState._(
      otp: otp ?? this.otp,
      result: result ?? this.result,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        otp,
        result,
        exception,
        isLoading,
      ];
}
