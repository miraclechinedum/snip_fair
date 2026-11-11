import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:snip_fair/core/presentation/configuration_error_app.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';
import 'package:snip_fair/main_development.dart' as development;
import 'package:snip_fair/main_production.dart' as production;
import 'package:snip_fair/main_staging.dart' as staging;

/// The default entry point (a build or run without `-t`). It starts the
/// app for the build's own flavor, so `flutter build apk --flavor
/// production` without a target still produces the production app — never
/// a placeholder, and never another environment.
Future<void> main() {
  switch (environmentForFlavor(appFlavor)) {
    case Environment.prod:
      return production.main();
    case Environment.staging:
      return staging.main();
    case Environment.dev:
      return development.main();
    default:
      WidgetsFlutterBinding.ensureInitialized();
      runApp(
        const ConfigurationErrorApp(
          message: 'This build has no flavor. Build or run with '
              '--flavor production, staging or development.',
        ),
      );
      return Future.value();
  }
}

/// The environment for a native [flavor]; null when there is none.
String? environmentForFlavor(String? flavor) => Environment.flavorFor.entries
    .where((entry) => entry.value == flavor)
    .map((entry) => entry.key)
    .firstOrNull;
