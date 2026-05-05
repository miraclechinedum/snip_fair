import 'package:auto_route/auto_route.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/app_config/app_config_controller.dart';

class RemoteKillSwitchRouteGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (getIt.isRegistered<AppConfigController>() &&
        getIt<AppConfigController>().isBlocked) {
      resolver.next(false);
      return;
    }

    resolver.next(true);
  }
}
