import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:formz/formz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/domain/params/register_params.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
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
    emit(state.copyWith(firstName: StringInput.dirty(value.trim())));
  }

  void onLastNameChanged(String value) {
    emit(state.copyWith(lastName: StringInput.dirty(value.trim())));
  }

  void onPhoneChanged(String value) {
    emit(state.copyWith(phone: PhoneInput.dirty(value.trim())));
  }

  void onEmailChanged(String value) {
    emit(state.copyWith(email: EmailInput.dirty(value.trim())));
  }

  void onPasswordChanged(String value) {
    final passwordInput =
        PasswordInput.dirty(value: value.trim(), pinLenght: 8);
    emit(
      state.copyWith(
        password: passwordInput,
        confirmPassword: ConfirmPasswordInput.dirty(
          passwordInput,
          state.confirmPassword.value,
        ),
      ),
    );
  }

  void onConfirmPasswordChanged(String value) {
    emit(
      state.copyWith(
        confirmPassword:
            ConfirmPasswordInput.dirty(state.password, value.trim()),
      ),
    );
  }

  void onTogglePassword() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }

  void onAcceptTermsChanged(bool value) {
    emit(state.copyWith(acceptTerms: value));
  }

  Future<void> signUpAsCustomer() async {
    final deviceInfo = await AppHelper.getDeviceInfo();
    await launchApiCall(
      () => _repository.registerCustomer(
        RegisterParams(
          phone: state.phone.value,
          firstName: state.firstName.value,
          lastName: state.lastName.value,
          passwordConfirmation: state.password.value,
          email: state.email.value,
          password: state.password.value,
          deviceName: Platform.isAndroid
              ? AndroidDeviceInfo.fromMap(deviceInfo.data).manufacturer
              : IosDeviceInfo.fromMap(deviceInfo.data).modelName,
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

  Future<void> signUpAsStylist() async {
    final deviceInfo = await AppHelper.getDeviceInfo();
    await launchApiCall(
      () => _repository.registerStylist(
        RegisterParams(
          phone: state.phone.value,
          firstName: state.firstName.value,
          lastName: state.lastName.value,
          passwordConfirmation: state.password.value,
          email: state.email.value,
          password: state.password.value,
          deviceName: Platform.isAndroid
              ? AndroidDeviceInfo.fromMap(deviceInfo.data).manufacturer
              : IosDeviceInfo.fromMap(deviceInfo.data).modelName,
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
