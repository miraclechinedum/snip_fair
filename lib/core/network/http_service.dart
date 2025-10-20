import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:injectable/injectable.dart' hide Environment;
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/error_interceptor.dart';
import 'package:snip_fair/core/presentation/app.dart';
import 'package:snip_fair/core/routing/routes.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';

import '../utils/environment/environment.dart';
import 'token_interceptor.dart';

@Injectable()
class HttpService {
  Dio client({bool requireAuth = true, bool isFormDataRequest = false}) => Dio(
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
              // Handle token expiration (e.g., refresh token)
              await appRouter.replaceAll([const LandingRoute()]);
              Fluttertoast.showToast(
                msg: 'Session expired. Please log in again.',
              );
            },
          ),
        )
        ..interceptors.add(
          LogInterceptor(
            responseHeader: true,
            responseBody: true,
            requestBody: true,
          ),
        );
}
