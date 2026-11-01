import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  static Future<String> getDeviceType() async {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // `androidId` was dropped from device_info_plus (always null since
      // 4.0.0, removed later), so this has always resolved to `id`
      // (android.os.Build.ID). A per-device Android ID would need the
      // separate `android_id` package.
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    }
    return 'unknown';
  }
}
