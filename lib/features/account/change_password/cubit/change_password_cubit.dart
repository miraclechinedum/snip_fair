import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/utils/input/input.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';

part 'change_password_state.dart';

@Injectable()
class ChangePasswordCubit extends BaseCubit<ChangePasswordState> {
  ChangePasswordCubit(this._profileRepository) : super(const ChangePasswordState.initial());

  final ProfileRepository _profileRepository;

  void onCurrentPassChanged(String value) {
    emit(
      state.copyWith(
        currentPassword: StringInput.dirty(value.trim()),
      ),
    );
  }

  void onNewPassChanged(String value) {
    final passwordInput = PasswordInput.dirty(value: value.trim());
    emit(
      state.copyWith(
        newPassword: passwordInput,
        confirmNewPassword: ConfirmPasswordInput.dirty(
          passwordInput,
          state.confirmNewPassword.value,
        ),
      ),
    );
  }

  void onConfirmNewPassChanged(String value) {
    emit(
      state.copyWith(
        confirmNewPassword: ConfirmPasswordInput.dirty(state.newPassword, value),
      ),
    );
  }

  Future<void> changePassword() async {
    await launchApiCall(
      () => _profileRepository.updatePassword(
        currentPassword: state.currentPassword.value,
        newPassword: state.newPassword.value,
      ),
      doOnLoading: () => emit(
        state.copyWith(chagePasswordState: const ProcessState.loading()),
      ),
      doOnError: (p0) => emit(state.copyWith(chagePasswordState: ProcessState.error(p0))),
      doOnSuccess: (p0) => emit(
        state.copyWith(chagePasswordState: const ProcessState.success(true)),
      ),
    );
  }

  void onTogglePassword() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }
}
