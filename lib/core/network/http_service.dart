import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/routing/routes.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:snip_fair/core/presentation/app.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:injectable/injectable.dart' hide Environment;
import 'package:snip_fair/core/network/error_interceptor.dart';
import 'package:snip_fair/core/network/token_interceptor.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';

@Injectable()
class HttpService {
  Dio client({bool requireAuth = true, bool isFormDataRequest = false}) => Dio(
        BaseOptions(
          baseUrl: Environment().config.apiHost,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          validateStatus: (status) => status != null && status >= 200 && status < 300,
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
        // ..interceptors.add(CookieManager(getIt<CookieJar>()))
        ..interceptors.add(
          TokenInterceptor(
            requireAuth: requireAuth,
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
        ..interceptors.add(
          LogInterceptor(
            responseBody: true,
            requestBody: true,
          ),
        );
}
