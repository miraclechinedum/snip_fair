import 'dart:async';

import 'package:dio/dio.dart';

/// Callback invoked when auth token is expired (HTTP 401).
/// Optionally receives the failed request's [RequestOptions].
typedef OnAuthTokenExpired = FutureOr<void> Function(
    RequestOptions failedRequest);

/// Dio interceptor that detects 401 responses and invokes [onAuthTokenExpired].
class ErrorInterceptor extends Interceptor {
  final OnAuthTokenExpired? onAuthTokenExpired;

  ErrorInterceptor({this.onAuthTokenExpired});

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 && onAuthTokenExpired != null) {
      // Call the callback but don't block the error propagation.
      try {
        final result = onAuthTokenExpired!(err.requestOptions);
        if (result is Future) {
          result.catchError((_) {});
        }
      } catch (_) {
        // Swallow callback errors to avoid interfering with normal error flow.
      }
    }

    // Continue the error chain.
    handler.next(err);
  }
}
