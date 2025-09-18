import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart' hide Environment;

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
          validateStatus: (status) => status == 200 || status == 201,
          headers: {
            'Accept':
                'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
            if (isFormDataRequest)
              'Content-Type': 'application/x-www-form-urlencoded'
            else
              'Content-type': 'application/json'
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
          LogInterceptor(
            responseHeader: true,
            responseBody: true,
            requestBody: true,
          ),
        );
}
