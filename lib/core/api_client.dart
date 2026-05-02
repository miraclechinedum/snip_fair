import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'device_utils.dart';

class ApiClient {
  static final Dio _dio = Dio();

  static Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final info = await PackageInfo.fromPlatform();
    final version = info.buildNumber;
    final deviceType = await DeviceUtils.getDeviceType();
    final deviceId = await DeviceUtils.getDeviceId();
    final Map<String, dynamic> allHeaders = {
      ...?headers,
      'x-app-version': version,
      'x-device-type': deviceType,
      'x-device-id': deviceId,
    };
    return _dio.request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(method: method, headers: allHeaders),
    );
  }
}
