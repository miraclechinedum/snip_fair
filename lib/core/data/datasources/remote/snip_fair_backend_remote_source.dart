import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/datasources/remote/base_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/domain/params/login_params.dart';
import 'package:snip_fair/core/domain/params/register_params.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';

class AuthPath {
  // Auth
  static const login = '/login';
  static const registerCustomer = '/register/customer';
  static const forgotPassword = '/forgot-password';
  static const logout = '/user/logout';
  static const user = '/user'; // GET
  static const resendEmailOtp = '/user/resend-email-otp';
  static const verifyEmailOtp = '/user/verify-email-otp';
  static const updatePassword = '/user/password'; //PATCH

  //Location
  static const updateLocationConsent = '/user/location/consent';
  static const updateCurrentLocation = '/user/location'; // Patch
}

@LazySingleton()
class SnipFairBackendRemoteSource extends BaseRemoteSource
    implements AuthenticationRepository, ProfileRepository {
  @override
  Future<ApiResult<SimpleResponse>> forgotPassowrd(String email) {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.forgotPassword,
        data: {'email': email},
      );
      return ApiResult.success(data: SimpleResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<User>> getUser() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final result = await client.get<Map<String, dynamic>>(AuthPath.user);
      return ApiResult.success(data: User.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<LoginResponse>> login(LoginParams data) {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.login,
        data: data.toJson(),
      );
      return ApiResult.success(data: LoginResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> logout() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.logout,
      );
      return ApiResult.success(data: SimpleResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<LoginResponse>> registerCustomer(RegisterParams data) {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.registerCustomer,
        data: data.toJson(),
      );
      return ApiResult.success(data: LoginResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> resendVerificationEmail(String email) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.resendEmailOtp,
        data: {'email': email},
      );
      return ApiResult.success(data: SimpleResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final result = await client.patch<Map<String, dynamic>>(
        AuthPath.updatePassword,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> verifyEmail(String otp) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.verifyEmailOtp,
        data: {'otp': otp},
      );
      return ApiResult.success(data: SimpleResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateLocationConsent(bool value) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.updateLocationConsent,
        data: {'consent_given': value},
      );
      return ApiResult.success(data: SimpleResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateUserLocation({
    required num latitude,
    required num longitude,
    required num accuracy,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final result = await client.patch<Map<String, dynamic>>(
        AuthPath.updateCurrentLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson(result.data!));
    });
  }
}
