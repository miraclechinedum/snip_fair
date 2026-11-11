import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:snip_fair/core/utils/environment/base_config.dart';
import 'package:snip_fair/core/utils/environment/environment_configs.dart';

class Environment {
  factory Environment() {
    return _singleton;
  }

  Environment._internal();
  static final Environment _singleton = Environment._internal();

  static const String dev = 'dev';
  static const String staging = 'staging';
  static const String prod = 'prod';

  /// The native flavor (`--flavor`) each environment belongs to.
  static const flavorFor = {
    prod: 'production',
    staging: 'staging',
    dev: 'development',
  };

  /// Set by [initConfig] before the app starts; tests may assign it.
  late BaseConfig config;

  /// Loads and validates [environment]'s configuration. Must complete
  /// before anything creates an API client (see `bootstrap`). Throws
  /// [EnvironmentConfigException] rather than fall back to another backend.
  Future<void> initConfig(String environment, {String? flavor = appFlavor}) async {
    checkFlavor(environment, flavor: flavor);
    await dotenv.load();
    config = resolveConfig(environment, dotenv.env);
  }

  /// A build's entry point must match its native flavor: a production app
  /// (bundle `com.snipfair.app`) can never run the development or staging
  /// configuration, and vice versa. [flavor] is null only for builds made
  /// without `--flavor` (e.g. tests), which are not distributable.
  static void checkFlavor(String environment, {String? flavor = appFlavor}) {
    if (flavor == null) return;
    final expected = flavorFor[environment];
    if (expected != flavor) {
      throw EnvironmentConfigException(
        'This "$flavor" build was started with the "$environment" entry '
        'point. Build it with the matching target, e.g. '
        '--flavor $flavor -t lib/main_$flavor.dart.',
      );
    }
  }
}
