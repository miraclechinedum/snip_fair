import 'package:snip_fair/core/utils/environment/base_config.dart';

/// The live Laravel API every production build must use — the same backend
/// and database as https://snipfair.com. Production refuses any other value.
const productionApiBaseUrl = 'https://snipfair.com/api';

/// The environment cannot start safely. Shown to the user instead of the app;
/// no request is ever made with a missing or unsafe API address.
class EnvironmentConfigException implements Exception {
  const EnvironmentConfigException(this.message);

  final String message;

  @override
  String toString() => 'EnvironmentConfigException: $message';
}

class DevConfig implements BaseConfig {
  const DevConfig(this.apiHost);

  @override
  final String apiHost;
  @override
  bool get reportErrors => false;
  @override
  bool get trackEvents => false;
  @override
  bool get useHttpsScheme => false;
}

class StagingConfig implements BaseConfig {
  const StagingConfig(this.apiHost);

  @override
  final String apiHost;
  @override
  bool get reportErrors => true;
  @override
  bool get trackEvents => false;
  @override
  bool get useHttpsScheme => true;
}

class ProdConfig implements BaseConfig {
  const ProdConfig(this.apiHost);

  @override
  final String apiHost;
  @override
  bool get reportErrors => true;
  @override
  bool get trackEvents => true;
  @override
  bool get useHttpsScheme => true;
}

/// The validated configuration for [environment] (`dev`, `staging` or
/// `prod`) from the bundled `.env` [values]. Never falls back to another
/// environment's backend:
/// - production must be exactly [productionApiBaseUrl];
/// - staging needs its own HTTPS backend — it may not point at production,
///   and an empty value means "no staging backend configured";
/// - development must not point at production.
BaseConfig resolveConfig(String environment, Map<String, String> values) {
  String required(String key, String label) {
    final value = values[key]?.trim() ?? '';
    if (value.isEmpty) {
      throw EnvironmentConfigException(
        '$label has no API address configured ($key in .env). '
        'This build cannot connect to a backend.',
      );
    }
    return value;
  }

  void notProduction(String url, String label) {
    final host = Uri.tryParse(url)?.host.toLowerCase();
    final productionHost = Uri.parse(productionApiBaseUrl).host;
    if (host == productionHost || host == 'www.$productionHost') {
      throw EnvironmentConfigException(
        '$label is pointed at the production backend ($url). It must use '
        'its own backend so it never writes to live data.',
      );
    }
  }

  switch (environment) {
    case 'prod':
      final url = required('PROD_API_BASE_URL', 'Production');
      if (url != productionApiBaseUrl) {
        throw EnvironmentConfigException(
          'Production must use $productionApiBaseUrl, but .env has $url.',
        );
      }
      return const ProdConfig(productionApiBaseUrl);
    case 'staging':
      final url = required('STAGING_API_BASE_URL', 'Staging');
      notProduction(url, 'Staging');
      if (Uri.tryParse(url)?.scheme != 'https') {
        throw EnvironmentConfigException(
          'Staging must use an HTTPS API address, not $url.',
        );
      }
      return StagingConfig(url);
    case 'dev':
      final url = required('DEV_API_BASE_URL', 'Development');
      notProduction(url, 'Development');
      return DevConfig(url);
    default:
      throw EnvironmentConfigException('Unknown environment "$environment".');
  }
}
