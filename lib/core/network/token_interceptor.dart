// ignore_for_file: omit_local_variable_types

import 'package:dio/dio.dart';
import 'package:snip_fair/core/di/injector.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor({
    required this.requireAuth,
  });

  final bool requireAuth;
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {}
}
