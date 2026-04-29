import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;

class VersionChecker {
  static const String minVersionKeyAndroid = 'min_required_version_android';
  static const String minVersionKeyIOS = 'min_required_version_ios';

  static void _log(String message) {
    print(message);
    developer.log(message, name: 'VersionChecker');
  }

  static int _compareVersionStrings(String a, String b) {
    final aParts = a
        .split(RegExp(r'[^0-9]+'))
        .where((p) => p.isNotEmpty)
        .map(int.parse)
        .toList();
    final bParts = b
        .split(RegExp(r'[^0-9]+'))
        .where((p) => p.isNotEmpty)
        .map(int.parse)
        .toList();
    final length = [aParts.length, bParts.length]
        .reduce((value, element) => value > element ? value : element);

    for (var i = 0; i < length; i++) {
      final aValue = i < aParts.length ? aParts[i] : 0;
      final bValue = i < bParts.length ? bParts[i] : 0;
      if (aValue != bValue) return aValue.compareTo(bValue);
    }
    return 0;
  }

  static Future<bool> isUpdateRequired() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      _log('Fetching Remote Config...');
      final activated = await remoteConfig.fetchAndActivate();
      _log('✅ Remote Config fetched and activated: activated=$activated');

      _log('Remote Config values:');
      remoteConfig.getAll().forEach((key, value) {
        _log('  $key = ${value.asString()} (source=${value.source})');
      });

      final info = await PackageInfo.fromPlatform();
      final String buildNumber = info.buildNumber;
      final String version = info.version;
      final String androidMinVersion =
          remoteConfig.getString(minVersionKeyAndroid);
      final String iosMinVersion = remoteConfig.getString(minVersionKeyIOS);

      _log('  Android min version string: $androidMinVersion');
      _log('  iOS min version string: $iosMinVersion');
      _log('  Current app version: $version');
      _log('  Current build number: $buildNumber');

      String minVersionString;
      String currentVersionString;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        minVersionString = iosMinVersion;
        currentVersionString = version;
        _log('iOS Version Check');
      } else {
        minVersionString = androidMinVersion;
        currentVersionString = version;
        _log('Android Version Check');
      }

      if (minVersionString.isEmpty) {
        _log('Min required version string is empty, skipping update check.');
        return false;
      }

      final comparison =
          _compareVersionStrings(currentVersionString, minVersionString);
      final updateRequired = comparison < 0;
      _log('Min Required Version: $minVersionString');
      _log('Current Version String: $currentVersionString');
      _log('Version comparison result: $comparison');
      _log('Update Required: $updateRequired (Current <$minVersionString)');
      return updateRequired;
    } catch (e, stackTrace) {
      _log('❌ Error during version check: $e');
      developer.log('❌ Error during version check: $e',
          name: 'VersionChecker', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  static Future<String> getMinRequiredVersion() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return remoteConfig.getString(minVersionKeyIOS);
    } else {
      return remoteConfig.getString(minVersionKeyAndroid);
    }
  }
}
