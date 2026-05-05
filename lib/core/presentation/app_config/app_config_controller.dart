import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:snip_fair/core/data/models/remote/app_config.dart';
import 'package:snip_fair/core/data/repositories/app_config_repository.dart';
import 'package:snip_fair/core/presentation/app_config/app_access_policy.dart';

class AppConfigController extends ChangeNotifier implements AppAccessPolicy {
  AppConfigController(this._repository);

  final AppConfigRepository _repository;

  AppConfig? _config;
  AppBlockReason? _blockReason;
  bool _isRefreshing = false;
  Object? _lastError;

  AppConfig? get config => _config;
  AppBlockReason? get blockReason => _blockReason;
  bool get isRefreshing => _isRefreshing;
  Object? get lastError => _lastError;
  bool get isBlocked => _blockReason != null;
  List<String> get announcements => _config?.announcements ?? const [];

  bool isFeatureEnabled(String key, {bool fallback = false}) {
    return _config?.featureFlags[key] ?? fallback;
  }

  @override
  bool get shouldBlockApiRequests => isBlocked;

  Future<void> refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final result = await _repository.getAppConfig();
      _lastError = result.error;
      _config = result.config;
      _blockReason = await _evaluate(result);
    } catch (error, stackTrace) {
      // Defensive fallback: unexpected local parsing/platform errors must not
      // become a kill switch by accident.
      log('App config evaluation failed: $error', stackTrace: stackTrace);
      _lastError = error;
      _config = AppConfig.defaults();
      _blockReason = null;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<AppBlockReason?> _evaluate(AppConfigRepositoryResult result) async {
    final config = result.config;

    if (result.isFromCache && _isStaleBlockedCache(result)) {
      log('Ignoring stale blocking app config cache.');
      return null;
    }

    if (!config.appEnabled) {
      return AppBlockReason.shutdown;
    }

    if (config.maintenanceMode) {
      return AppBlockReason.maintenance;
    }

    if (await _isVersionBlocked(config)) {
      return AppBlockReason.versionBlocked;
    }

    return null;
  }

  bool _isStaleBlockedCache(AppConfigRepositoryResult result) {
    final cachedAt = result.cachedAt;
    final config = result.config;
    final blocksAccess = !config.appEnabled || config.maintenanceMode;

    if (!blocksAccess || cachedAt == null) return false;

    return DateTime.now().difference(cachedAt) >
        AppConfigRepository.cachedConfigMaxAge;
  }

  Future<bool> _isVersionBlocked(AppConfig config) async {
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 1;
    final minimumBuild = Platform.isIOS
        ? config.minimumIosVersion
        : config.minimumAndroidVersion;

    return currentBuild < minimumBuild;
  }
}

enum AppBlockReason { shutdown, maintenance, versionBlocked }
