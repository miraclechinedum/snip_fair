import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:snip_fair/core/services/analytics_service.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/input/input.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/domain/params/register_params.dart';
import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:flutter/foundation.dart';

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

  void onGenderChanged(String value) {
    emit(state.copyWith(gender: StringInput.dirty(value.trim())));
  }

  void onPasswordChanged(String value) {
    final passwordInput = PasswordInput.dirty(value: value.trim());
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
        confirmPassword: ConfirmPasswordInput.dirty(state.password, value.trim()),
      ),
    );
  }

  void onTogglePassword() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }

  void onAcceptTermsChanged(bool value) {
    emit(state.copyWith(acceptTerms: value));
  }

  /// The registration request (customer or stylist). The email is trimmed
  /// and lowercased, matching the backend's normalisation; everything else
  /// is sent as entered.
  @visibleForTesting
  static RegisterParams registerParams(
    SignupState state, {
    required String deviceName,
  }) =>
      RegisterParams(
        phone: state.phone.value,
        firstName: state.firstName.value,
        lastName: state.lastName.value,
        passwordConfirmation: state.password.value,
        email: EmailInput.normalize(state.email.value),
        password: state.password.value,
        gender: state.gender.value,
        deviceName: deviceName,
      );

  Future<void> signUpAsCustomer() async {
    final deviceInfo = await AppHelper.getDeviceInfo();
    await launchApiCall(
      () => _repository.registerCustomer(
        registerParams(
          state,
          deviceName: Platform.isAndroid
              ? AndroidDeviceInfo.fromMap(deviceInfo.data).manufacturer
              : IosDeviceInfo.fromMap(deviceInfo.data).modelName,
        ),
      ),
      doOnLoading: () => emit(state.copyWith(signUpResult: const ProcessState.loading())),
      showError: false,
      doOnError: _emitSignUpError,
      doOnSuccess: (p0) {
        emit(state.copyWith(signUpResult: ProcessState.success(p0)));
        unawaited(AnalyticsService.instance.logSignUp(method: 'email'));
      },
    );
  }

  Future<void> signUpAsStylist() async {
    final deviceInfo = await AppHelper.getDeviceInfo();
    await launchApiCall(
      () => _repository.registerStylist(
        registerParams(
          state,
          deviceName: Platform.isAndroid
              ? AndroidDeviceInfo.fromMap(deviceInfo.data).manufacturer
              : IosDeviceInfo.fromMap(deviceInfo.data).modelName,
        ),
      ),
      doOnLoading: () => emit(state.copyWith(signUpResult: const ProcessState.loading())),
      showError: false,
      doOnError: _emitSignUpError,
      doOnSuccess: (p0) {
        emit(state.copyWith(signUpResult: ProcessState.success(p0)));
        unawaited(AnalyticsService.instance.logSignUp(method: 'email'));
      },
    );
  }

  /// Shows the sign-up failure through the page's usual error dialog, with a
  /// friendlier message when the email is already registered.
  void _emitSignUpError(Object error) {
    final shown = friendlySignUpError(error);
    emit(
      state.copyWith(
        signUpResult: ProcessState.error(shown),
        exception: shown is Exception ? shown : null,
      ),
    );
  }

  static const duplicateEmailMessage =
      'An account with this email address already exists. '
      'Log in instead, or sign up with a different email address.';

  /// Laravel rejects an already-registered email (compared case-insensitively)
  /// with HTTP 422 and `errors.email` "…has already been taken." That becomes
  /// [duplicateEmailMessage]; any other error is returned unchanged.
  @visibleForTesting
  static Object friendlySignUpError(Object error) {
    if (error is! RemoteException || error.statusCode != 422) return error;
    final emailErrors = error.errorResponse?.errors['email'];
    final messages = emailErrors is List
        ? emailErrors.whereType<String>()
        : emailErrors is String
            ? [emailErrors]
            : const <String>[];
    final isDuplicate = messages.any(
      (m) => m.toLowerCase().contains('already been taken'),
    );
    if (!isDuplicate) return error;
    return RemoteException.serverError(
      error.statusCode,
      ServerError(
        message: duplicateEmailMessage,
        errors: error.errorResponse?.errors ?? const {},
      ),
      code: error.code,
      responseBody: error.responseBody,
    );
  }

  final _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
      _isGoogleSignInInitialized = true;
    } catch (e) {
      print('Error initializing Google Sign-In: $e');
    }
  }

  /// Always check Google sign in initialization before use
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  Future<void> loginWithGoogle({required bool isStylist}) async {
    await _ensureGoogleSignInInitialized();

    emit(state.copyWith(googleLoginResult: const ProcessState.loading()));

    try {
      // authenticate() throws exceptions instead of returning null
      await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'], // Specify required scopes
      );
      // Get authorization for Firebase scopes if needed
      final authClient = _googleSignIn.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email', 'profile']);

      if (authorization == null) return;

      await _loginWithGoogle(
        accessToken: authorization.accessToken,
        role: isStylist ? 'stylist' : 'customer',
      );
    } on GoogleSignInException catch (e) {
      emit(state.copyWith(googleLoginResult: ProcessState.error(e)));
    } catch (error) {
      emit(state.copyWith(googleLoginResult: ProcessState.error(error)));
    }
  }

  Future<void> _loginWithGoogle({
    required String accessToken,
    required String role,
  }) async {
    try {
      final deviceInfo = await AppHelper.getDeviceInfo();

      await launchApiCall(
        () => _repository.loginWithGoogle(
          accessToken: accessToken,
          role: role,
          device: Platform.isAndroid
              ? AndroidDeviceInfo.fromMap(deviceInfo.data).manufacturer
              : IosDeviceInfo.fromMap(deviceInfo.data).modelName,
        ),
        doOnLoading: () => emit(state.copyWith(signUpResult: const ProcessState.loading())),
        doOnError: (p0) => emit(state.copyWith(signUpResult: ProcessState.error(p0))),
        doOnSuccess: (p0) {
          emit(state.copyWith(signUpResult: ProcessState.success(p0)));
          unawaited(AnalyticsService.instance.logLogin(method: 'google'));
        },
      );
    } catch (e) {
      emit(state.copyWith(signUpResult: ProcessState.error(e)));
    }
  }
}
