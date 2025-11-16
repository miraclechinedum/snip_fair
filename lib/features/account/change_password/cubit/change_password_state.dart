part of 'change_password_cubit.dart';

class ChangePasswordState extends BaseState {
  const ChangePasswordState._({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
    required this.showPassword,
    required this.chagePasswordState,
    super.exception,
    super.isLoading,
  });

  const ChangePasswordState.initial()
      : this._(
          currentPassword: const StringInput.pure(),
          newPassword: const PasswordInput.pure(),
          confirmNewPassword:
              const ConfirmPasswordInput.pure(PasswordInput.pure()),
          chagePasswordState: const ProcessState.init(null),
          showPassword: false,
        );

  final StringInput currentPassword;
  final PasswordInput newPassword;
  final ConfirmPasswordInput confirmNewPassword;
  final bool showPassword;
  final ProcessState<bool> chagePasswordState;

  bool get canSubmit =>
      Formz.validate([currentPassword, newPassword, confirmNewPassword]) &&
      !chagePasswordState.isLoading;

  @override
  ChangePasswordState copyWith({
    StringInput? currentPassword,
    PasswordInput? newPassword,
    ConfirmPasswordInput? confirmNewPassword,
    ProcessState<bool>? chagePasswordState,
    bool? showPassword,
    Exception? exception,
    bool? isLoading,
  }) {
    return ChangePasswordState._(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmNewPassword: confirmNewPassword ?? this.confirmNewPassword,
      chagePasswordState: chagePasswordState ?? this.chagePasswordState,
      showPassword: showPassword ?? this.showPassword,
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        currentPassword,
        newPassword,
        confirmNewPassword,
        chagePasswordState,
        showPassword,
        exception,
        isLoading,
      ];
}
