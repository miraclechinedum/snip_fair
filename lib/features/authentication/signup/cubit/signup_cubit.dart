import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/domain/params/register_params.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/input.dart';

part 'signup_state.dart';

@Injectable()
class SignupCubit extends BaseCubit<SignupState> {
  SignupCubit(
    this._repository,
  ) : super(const SignupState.initial());

  final AuthenticationRepository _repository;

  void onFirstNameChanged(String value) {
    emit(state.copyWith(firstName: StringInput.dirty(value)));
  }

  void onLastNameChanged(String value) {
    emit(state.copyWith(lastName: StringInput.dirty(value)));
  }

  void onPhoneChanged(String value) {
    emit(state.copyWith(phone: PhoneInput.dirty(value)));
  }

  void onEmailChanged(String value) {
    emit(state.copyWith(email: EmailInput.dirty(value)));
  }

  void onPasswordChanged(String value) {
    emit(state.copyWith(password: PasswordInput.dirty(value: value)));
  }

  void onConfirmPasswordChanged(String value) {
    emit(
      state.copyWith(
        confirmPassword: ConfirmPasswordInput.dirty(state.password, value),
      ),
    );
  }

  void onAcceptTermsChanged(bool value) {
    emit(state.copyWith(acceptTerms: value));
  }

  Future<void> signUp() async {
    await launchApiCall(
      () => _repository.registerCustomer(
        RegisterParams(
          phone: state.phone.value,
          firstName: state.firstName.value,
          lastName: state.lastName.value,
          passwordConfirmation: state.password.value,
          email: state.email.value,
          password: state.password.value,
          deviceName: '',
        ),
      ),
      doOnLoading: () =>
          emit(state.copyWith(signUpResult: const ProcessState.loading())),
      doOnError: (p0) =>
          emit(state.copyWith(signUpResult: ProcessState.error(p0))),
      doOnSuccess: (p0) =>
          emit(state.copyWith(signUpResult: ProcessState.success(p0))),
    );
  }
}
