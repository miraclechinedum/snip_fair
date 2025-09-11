import 'package:snip_fair/bootstrap.dart';
import 'package:snip_fair/core/presentation/app.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';

void main() {
  Environment().initConfig(Environment.prod);
  bootstrap(() => const App());
}
