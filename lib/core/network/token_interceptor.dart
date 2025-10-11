// ignore_for_file: omit_local_variable_types

import 'package:dio/dio.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor({
    required this.requireAuth,
  });

  final bool requireAuth;
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (requireAuth) {
      final token = getIt<LocalKeyStorage>().accessToken;
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
