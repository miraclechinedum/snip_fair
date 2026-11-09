import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/routing/routes.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:snip_fair/core/presentation/app.dart';
import 'package:snip_fair/core/presentation/app_config/app_access_policy.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:injectable/injectable.dart' hide Environment;
import 'package:snip_fair/core/network/error_interceptor.dart';
import 'package:snip_fair/core/network/redacting_log_interceptor.dart';
import 'package:snip_fair/core/network/token_interceptor.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';

/// Temporary switch for the verbose global Dio request/response logging.
///
/// Kept `false` while the Peach Payments flows are being tested so the console
/// only carries the concise `[PEACH]` payment logs. Flip to `true` to restore
/// the HTTP dumps — always through [RedactingLogInterceptor], so tokens,
/// idempotency keys, cookies and sensitive body fields are never printed.
const bool kEnableVerboseHttpLogging = false;

@Injectable()
class HttpService {
  /// Whether clients log every request and response (redacted). Defaults to
  /// [kEnableVerboseHttpLogging]; tests switch it on to check the redaction.
  @visibleForTesting
  static bool verboseLogging = kEnableVerboseHttpLogging;

  Dio client({
    bool requireAuth = true,
    bool optionalAuth = false,
    bool isFormDataRequest = false,
  }) =>
      Dio(
        BaseOptions(
          baseUrl: Environment().config.apiHost,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
          headers: {
            'Accept':
                'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
            if (isFormDataRequest)
              'Content-Type': 'application/x-www-form-urlencoded'
            else
              'Content-type': 'application/json',
          },
        ),
      )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final isAppConfigRequest = options.path == '/app-config';
              final accessIsBlocked = getIt.isRegistered<AppAccessPolicy>() &&
                  getIt<AppAccessPolicy>().shouldBlockApiRequests;

              if (!isAppConfigRequest && accessIsBlocked) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.cancel,
                    error: 'App access is blocked by remote configuration.',
                  ),
                );
                return;
              }

              handler.next(options);
            },
          ),
        )
        // ..interceptors.add(CookieManager(getIt<CookieJar>()))
        ..interceptors.add(
          TokenInterceptor(
            requireAuth: requireAuth,
            optionalAuth: optionalAuth,
          ),
        )
        ..interceptors.add(
          ErrorInterceptor(
            onAuthTokenExpired: (failedRequest) async {
              final appRouter = getIt<AppRouter>();

              if (appRouter.current.name == LandingRoute.name) {
                return;
              }

              Fluttertoast.showToast(
                msg: 'Session expired. Please log in again.',
              );
              // Handle token expiration (e.g., refresh token)
              await appRouter.replaceAll([const LandingRoute()]);
            },
          ),
        )
        ..interceptors.addAll([
          // Last, so it sees the Authorization header TokenInterceptor adds.
          if (verboseLogging) RedactingLogInterceptor(),
        ]);
}
