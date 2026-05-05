import 'package:dio/dio.dart';
import 'package:snip_fair/core/data/models/remote/app_config.dart';
import 'package:snip_fair/core/network/http_service.dart';

class AppConfigPath {
  static const appConfig = '/app-config';
}

class AppConfigService {
  AppConfigService(this._httpService);

  final HttpService _httpService;

  Future<AppConfig> fetchAppConfig() async {
    final client = _httpService.client(requireAuth: false);
    final response = await client.get<Map<String, dynamic>>(
      AppConfigPath.appConfig,
      options: Options(
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final data = response.data;
    if (data == null) {
      throw StateError('Empty /app-config response');
    }

    return AppConfig.fromJson(data);
  }
}
