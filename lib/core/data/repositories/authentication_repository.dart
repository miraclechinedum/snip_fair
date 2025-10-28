import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/domain/params/login_params.dart';
import 'package:snip_fair/core/domain/params/register_params.dart';
import 'package:snip_fair/core/network/handlers.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';

abstract class AuthenticationRepository {
  Future<ApiResult<LoginResponse>> login(LoginParams data);
  Future<ApiResult<LoginResponse>> registerCustomer(RegisterParams data);
  Future<ApiResult<LoginResponse>> registerStylist(RegisterParams data);
  Future<ApiResult<SimpleResponse>> forgotPassowrd(String email);
  Future<ApiResult<SimpleResponse>> resendVerificationEmail(String email);
  Future<ApiResult<SimpleResponse>> verifyEmail(String otp);
  Future<ApiResult<LoginResponse>> loginWithGoogle({
    required String accessToken,
    required String role,
    required String device,
  });
}

@Injectable(as: AuthenticationRepository)
class AuthenticationRepoImpl implements AuthenticationRepository {
  AuthenticationRepoImpl(this._localKeyStorage, this._remoteSource);

  final LocalKeyStorage _localKeyStorage;
  final SnipFairBackendRemoteSource _remoteSource;

  @override
  Future<ApiResult<SimpleResponse>> forgotPassowrd(String email) =>
      _remoteSource.forgotPassowrd(email);

  @override
  Future<ApiResult<LoginResponse>> login(LoginParams data) async {
    final result = await _remoteSource.login(data);
    return result.map(
      success: (data) {
        if (data.data.user != null) {
          _localKeyStorage
            ..saveCurrentUser(data.data.user!)
            ..saveAccessToken(data.data.token!);
        }
        return data;
      },
      failure: (f) => f,
    );
  }

  @override
  Future<ApiResult<LoginResponse>> registerCustomer(RegisterParams data) async {
    final result = await _remoteSource.registerCustomer(data);
    return result.map(
      success: (data) {
        if (data.data.user != null) {
          _localKeyStorage
            ..saveCurrentUser(data.data.user!)
            ..saveAccessToken(data.data.token!);
        }
        return data;
      },
      failure: (f) => f,
    );
  }

  @override
  Future<ApiResult<SimpleResponse>> resendVerificationEmail(String email) =>
      _remoteSource.resendVerificationEmail(email);

  @override
  Future<ApiResult<SimpleResponse>> verifyEmail(String otp) =>
      _remoteSource.verifyEmail(otp);

  @override
  Future<ApiResult<LoginResponse>> registerStylist(RegisterParams data) async {
    final result = await _remoteSource.registerStylist(data);
    return result.map(
      success: (data) {
        if (data.data.user != null) {
          _localKeyStorage
            ..saveCurrentUser(data.data.user!)
            ..saveAccessToken(data.data.token!);
        }
        return data;
      },
      failure: (f) => f,
    );
  }

  @override
  Future<ApiResult<LoginResponse>> loginWithGoogle({
    required String accessToken,
    required String role,
    required String device,
  }) async {
    final result = await _remoteSource.loginWithGoogle(
      accessToken: accessToken,
      role: role,
      device: device,
    );

    return result.map(
      success: (data) {
        if (data.data.user != null) {
          _localKeyStorage
            ..saveCurrentUser(data.data.user!)
            ..saveAccessToken(data.data.token!);
        }
        return data;
      },
      failure: (f) => f,
    );
  }
}
