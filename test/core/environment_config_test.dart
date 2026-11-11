import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snip_fair/bootstrap.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/presentation/configuration_error_app.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';
import 'package:snip_fair/core/utils/environment/environment_configs.dart';
import 'package:snip_fair/main.dart' as entry;

Matcher _configError(String fragment) => throwsA(
      isA<EnvironmentConfigException>()
          .having((e) => e.message, 'message', contains(fragment)),
    );

const _env = {
  'DEV_API_BASE_URL': 'http://127.0.0.1:8002/api',
  'STAGING_API_BASE_URL': 'https://staging-api.example.test/api',
  'PROD_API_BASE_URL': 'https://snipfair.com/api',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveConfig', () {
    test('production is exactly https://snipfair.com/api', () {
      final config = resolveConfig(Environment.prod, _env);
      expect(config, isA<ProdConfig>());
      expect(config.apiHost, 'https://snipfair.com/api');
      expect(config.apiHost, productionApiBaseUrl);
    });

    test('production refuses any other address', () {
      for (final url in [
        'https://staging-api.example.test/api',
        'http://snipfair.com/api',
        'https://www.snipfair.com/api',
        '',
      ]) {
        expect(
          () => resolveConfig(Environment.prod, {
            ..._env,
            'PROD_API_BASE_URL': url,
          }),
          throwsA(isA<EnvironmentConfigException>()),
          reason: url,
        );
      }
    });

    test('staging with no backend configured refuses to start', () {
      expect(
        () => resolveConfig(Environment.staging, {
          ..._env,
          'STAGING_API_BASE_URL': '',
        }),
        _configError('no API address'),
      );
      expect(
        () => resolveConfig(Environment.staging, {
          'PROD_API_BASE_URL': productionApiBaseUrl,
        }),
        _configError('no API address'),
      );
    });

    test('staging never falls back to (or points at) production', () {
      for (final url in [
        'https://snipfair.com/api',
        'https://www.snipfair.com/api',
        'https://SNIPFAIR.com/api',
      ]) {
        expect(
          () => resolveConfig(Environment.staging, {
            ..._env,
            'STAGING_API_BASE_URL': url,
          }),
          _configError('production backend'),
          reason: url,
        );
      }
    });

    test('staging must be HTTPS', () {
      expect(
        () => resolveConfig(Environment.staging, {
          ..._env,
          'STAGING_API_BASE_URL': 'http://staging-api.example.test/api',
        }),
        _configError('HTTPS'),
      );
    });

    test('a real staging backend is accepted', () {
      final config = resolveConfig(Environment.staging, _env);
      expect(config, isA<StagingConfig>());
      expect(config.apiHost, 'https://staging-api.example.test/api');
    });

    test('development uses its local backend, never production', () {
      expect(
        resolveConfig(Environment.dev, _env).apiHost,
        'http://127.0.0.1:8002/api',
      );
      expect(
        () => resolveConfig(Environment.dev, {
          ..._env,
          'DEV_API_BASE_URL': 'https://snipfair.com/api',
        }),
        _configError('production backend'),
      );
      expect(
        () => resolveConfig(Environment.dev, {
          ..._env,
          'DEV_API_BASE_URL': '',
        }),
        _configError('no API address'),
      );
    });
  });

  group('the bundled .env', () {
    test('production → https://snipfair.com/api', () async {
      await Environment().initConfig(Environment.prod, flavor: 'production');
      expect(Environment().config.apiHost, 'https://snipfair.com/api');
    });

    test('development → the local backend', () async {
      await Environment().initConfig(Environment.dev, flavor: 'development');
      expect(Environment().config.apiHost, 'http://127.0.0.1:8002/api');
    });

    test('staging → refused: no staging backend exists yet', () async {
      await expectLater(
        Environment().initConfig(Environment.staging, flavor: 'staging'),
        throwsA(isA<EnvironmentConfigException>()),
      );
    });
  });

  group('entry point and flavor', () {
    test('each entry point belongs to exactly one flavor', () {
      Environment.checkFlavor(Environment.prod, flavor: 'production');
      Environment.checkFlavor(Environment.staging, flavor: 'staging');
      Environment.checkFlavor(Environment.dev, flavor: 'development');
      // Builds without --flavor (tests) are not checked.
      Environment.checkFlavor(Environment.dev, flavor: null);
    });

    test('a mismatched build refuses to start', () {
      expect(
        () => Environment.checkFlavor(Environment.dev, flavor: 'production'),
        _configError('lib/main_production.dart'),
      );
      expect(
        () => Environment.checkFlavor(Environment.prod, flavor: 'development'),
        throwsA(isA<EnvironmentConfigException>()),
      );
      expect(
        () => Environment().initConfig(Environment.dev, flavor: 'production'),
        throwsA(isA<EnvironmentConfigException>()),
      );
    });

    test('lib/main.dart starts the build\'s own flavor', () {
      expect(entry.environmentForFlavor('production'), Environment.prod);
      expect(entry.environmentForFlavor('staging'), Environment.staging);
      expect(entry.environmentForFlavor('development'), Environment.dev);
      expect(entry.environmentForFlavor(null), isNull);
      expect(entry.environmentForFlavor('other'), isNull);
    });

    test('each flavor entry point selects its own environment', () {
      for (final (file, environment) in [
        ('lib/main_production.dart', 'Environment.prod'),
        ('lib/main_staging.dart', 'Environment.staging'),
        ('lib/main_development.dart', 'Environment.dev'),
      ]) {
        final source = File(file).readAsStringSync();
        expect(source, contains('environment: $environment'), reason: file);
        expect(source, contains('bootstrap('), reason: file);
      }
      expect(
        File('lib/main.dart').readAsStringSync(),
        isNot(contains('Hello World')),
      );
    });

    testWidgets('a build without a flavor shows a configuration error',
        (tester) async {
      await entry.main();
      await tester.pump();

      expect(find.byType(ConfigurationErrorApp), findsOneWidget);
      expect(find.textContaining('--flavor production'), findsOneWidget);
    });
  });

  testWidgets(
      'startup: the environment is validated before any dependency or API '
      'client exists', (tester) async {
    await getIt.reset();
    // bootstrap installs its own global error handler: restore the test's.
    final onError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = onError);

    // The bundled .env has no staging backend. Real asset I/O: run it
    // outside the test's fake clock.
    await tester.runAsync(
      () => bootstrap(() => const SizedBox(), environment: Environment.staging),
    );
    await tester.pump();

    expect(find.byType(ConfigurationErrorApp), findsOneWidget);
    expect(find.textContaining('STAGING_API_BASE_URL'), findsOneWidget);
    expect(getIt.isRegistered<HttpService>(), isFalse);
  });

  group('native configuration', () {
    test('Android: development has its own application id', () {
      final gradle = File('android/app/build.gradle').readAsStringSync();
      expect(gradle, contains('applicationId "com.snipfair.app"'));
      final flavors = RegExp(
        r'(production|staging|development) \{[^}]*applicationIdSuffix "([^"]*)"',
      ).allMatches(gradle);
      expect(
        {for (final m in flavors) m.group(1): m.group(2)},
        {'production': '', 'staging': '.stg', 'development': '.dev'},
      );
    });

    test('Android: production is HTTPS-only (cleartext only in dev/debug)', () {
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        isNot(contains('usesCleartextTraffic')),
      );
      for (final file in [
        'android/app/src/debug/AndroidManifest.xml',
        'android/app/src/development/AndroidManifest.xml',
      ]) {
        expect(
          File(file).readAsStringSync(),
          contains('android:usesCleartextTraffic="true"'),
          reason: file,
        );
      }
    });

    test('iOS: every configuration pins its flavor\'s entry point', () {
      final project =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      final configs = RegExp(
        r'/\* (Debug|Release|Profile)-(production|staging|development) \*/ = '
        r'\{\s*isa = XCBuildConfiguration;(.*?)\n\t\t\};',
        dotAll: true,
      ).allMatches(project);
      // The Runner app's configurations are the ones based on Flutter's
      // Debug/Release.xcconfig; project-level and RunnerTests configurations
      // share the same names.
      final runner = RegExp(
        r'baseConfigurationReference = \w+ /\* (Debug|Release)\.xcconfig \*/',
      );
      final runnerConfigs =
          configs.where((m) => runner.hasMatch(m.group(3)!)).toList();
      expect(runnerConfigs, hasLength(9));
      for (final m in runnerConfigs) {
        expect(
          m.group(3),
          contains('FLUTTER_TARGET = lib/main_${m.group(2)}.dart;'),
          reason: '${m.group(1)}-${m.group(2)}',
        );
      }
      expect(project, contains('Restrict ATS to development'));
    });

    test('iOS: Google sign-in is configured from GoogleService-Info.plist', () {
      final google =
          File('ios/Runner/GoogleService-Info.plist').readAsStringSync();
      final info = File('ios/Runner/Info.plist').readAsStringSync();
      String value(String plist, String key) => RegExp(
            '<key>$key</key>\\s*<string>([^<]+)</string>',
          ).firstMatch(plist)!.group(1)!;

      expect(value(info, 'GIDClientID'), value(google, 'CLIENT_ID'));
      expect(info, contains('<key>CFBundleURLSchemes</key>'));
      expect(info, contains(value(google, 'REVERSED_CLIENT_ID')));
    });

    test('Google sign-in is no longer hidden on iOS', () {
      for (final file in [
        'lib/features/authentication/login/views/login_screen.dart',
        'lib/features/authentication/signup/views/signup_screen.dart',
      ]) {
        expect(
          File(file).readAsStringSync(),
          isNot(contains('Platform.isIOS')),
          reason: file,
        );
      }
    });
  });
}
