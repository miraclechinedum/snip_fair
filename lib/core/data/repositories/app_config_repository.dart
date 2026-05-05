import 'dart:convert';

import 'package:snip_fair/core/data/models/remote/app_config.dart';
import 'package:snip_fair/core/data/services/app_config_service.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/preferences/config/shared_pref_key.dart';

class AppConfigRepositoryResult {
  const AppConfigRepositoryResult({
    required this.config,
    required this.source,
    this.cachedAt,
    this.error,
  });

  final AppConfig config;
  final AppConfigSource source;
  final DateTime? cachedAt;
  final Object? error;

  bool get isFromCache => source == AppConfigSource.cache;
}

enum AppConfigSource { remote, cache, defaults }

class AppConfigRepository {
  AppConfigRepository(this._service, this._localStorage);

  final AppConfigService _service;
  final LocalKeyStorage _localStorage;

  static const cachedConfigMaxAge = Duration(hours: 24);

  Future<AppConfigRepositoryResult> getAppConfig() async {
    try {
      final config = await _service.fetchAppConfig();
      await _cacheConfig(config);
      return AppConfigRepositoryResult(
        config: config,
        source: AppConfigSource.remote,
        cachedAt: DateTime.now(),
      );
    } catch (error) {
      final cached = _readCachedConfig();
      if (cached != null) {
        return AppConfigRepositoryResult(
          config: cached.config,
          source: AppConfigSource.cache,
          cachedAt: cached.cachedAt,
          error: error,
        );
      }

      // Safety rule: no network and no cache must never lock users out.
      return AppConfigRepositoryResult(
        config: AppConfig.defaults(),
        source: AppConfigSource.defaults,
        error: error,
      );
    }
  }

  Future<void> _cacheConfig(AppConfig config) async {
    final payload = jsonEncode(<String, dynamic>{
      'cached_at': DateTime.now().toIso8601String(),
      'config': config.toJson(),
    });

    await _localStorage.storeString(
      key: SharedPrefKey.appConfig,
      value: payload,
    );
  }

  _CachedAppConfig? _readCachedConfig() {
    final payload = _localStorage.getString(SharedPrefKey.appConfig);
    if (payload == null) return null;

    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final configJson = json['config'];
      if (configJson is! Map<String, dynamic>) return null;

      final cachedAtText = json['cached_at'] as String?;
      final cachedAt = cachedAtText == null
          ? null
          : DateTime.tryParse(cachedAtText)?.toLocal();

      return _CachedAppConfig(
        config: AppConfig.fromJson(configJson),
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }
}

class _CachedAppConfig {
  const _CachedAppConfig({required this.config, required this.cachedAt});

  final AppConfig config;
  final DateTime? cachedAt;
}
