// ignore_for_file: omit_local_variable_types

import 'package:dio/dio.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor({
    required this.requireAuth,
    this.optionalAuth = false,
  });

  final bool requireAuth;

  /// When true, attach the auth token if the user is logged in, but allow the
  /// request to proceed without it when there is no token (e.g. guest users).
  /// Takes precedence over [requireAuth].
  final bool optionalAuth;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = getIt<LocalKeyStorage>().accessToken;

    if (optionalAuth) {
      // Attach the token ONLY when the app is actually in an authenticated
      // session. A stored token can outlive its session (e.g. user logs in,
      // taps "guest mode" later, or a logout leaves the token behind), and
      // sending a stale token on a guest-mode request has caused the backend
      // to 500 rather than treat the request as anonymous. So we check the
      // live auth state, not just token presence.
      final isAuthed = getIt.isRegistered<AppCubit>() &&
          getIt<AppCubit>().state.status == AuthStatus.authenticated;
      if (token != null && isAuthed) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
      return;
    }

    if (requireAuth) {
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      } else {
        handler.reject(
          DioException(
            requestOptions: options,
            message: 'Provide Auth Credentials',
          ),
        );
      }
    } else {
      handler.next(options);
    }
  }
}
