import 'package:snip_fair/bootstrap.dart';
import 'package:snip_fair/core/presentation/app.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';

/// Entry point for `--flavor development`. The environment is loaded and checked
/// against the build's flavor inside [bootstrap], before anything starts.
Future<void> main() => bootstrap(
      () => const App(),
      environment: Environment.dev,
    );
