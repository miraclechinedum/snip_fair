import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:formz/formz.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/domain/params/login_params.dart';
import 'package:snip_fair/core/utils/base/base_cubit.dart';
import 'package:snip_fair/core/utils/base/base_state.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/email_input.dart';
import 'package:snip_fair/core/utils/input/password_input.dart';
import 'package:snip_fair/core/utils/utils.dart';

part 'login_state.dart';

@Injectable()
class LoginCubit extends BaseCubit<LoginState> {
  LoginCubit(
    this._repository,
  ) : super(LoginState.initial());

  final AuthenticationRepository _repository;

  void onEmailChanged(String value) {
    emit(state.copyWith(email: EmailInput.dirty(value.trim())));
  }

  void onPasswordChanged(String value) {
    emit(state.copyWith(password: PasswordInput.dirty(value: value.trim())));
  }

  void onTogglePassword() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }

  Future<void> login() async {
    try {
      final deviceInfo = await AppHelper.getDeviceInfo();

      await launchApiCall(
        () => _repository.login(
          LoginParams(
            email: state.email.value,
            password: state.password.value,
            deviceName: Platform.isAndroid
                ? AndroidDeviceInfo.fromMap(deviceInfo.data).manufacturer
                : IosDeviceInfo.fromMap(deviceInfo.data).modelName,
          ),
        ),
        doOnLoading: () =>
            emit(state.copyWith(loginResult: const ProcessState.loading())),
        doOnError: (p0) =>
            emit(state.copyWith(loginResult: ProcessState.error(p0))),
        doOnSuccess: (p0) =>
            emit(state.copyWith(loginResult: ProcessState.success(p0))),
      );
    } catch (e) {
      emit(state.copyWith(loginResult: ProcessState.error(e)));
    }
  }

  final _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
          clientId:
              '93247050443-p33nrtciphrksd5nj2moms95aqtfo939.apps.googleusercontent.com',
          serverClientId:
              '441775479731-jr325a94foktmtqh5ujqpfcffmh9rv79.apps.googleusercontent.com');
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
      final authorization =
          await authClient.authorizationForScopes(['email', 'profile']);

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
        doOnLoading: () =>
            emit(state.copyWith(loginResult: const ProcessState.loading())),
        doOnError: (p0) =>
            emit(state.copyWith(loginResult: ProcessState.error(p0))),
        doOnSuccess: (p0) =>
            emit(state.copyWith(loginResult: ProcessState.success(p0))),
      );
    } catch (e) {
      emit(state.copyWith(loginResult: ProcessState.error(e)));
    }
  }
}
