import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/app_config_repository.dart';
import 'package:snip_fair/core/data/services/app_config_service.dart';
import 'package:snip_fair/core/di/injector.config.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/presentation/app_config/app_access_policy.dart';
import 'package:snip_fair/core/presentation/app_config/app_config_controller.dart';
import 'package:snip_fair/core/routing/routes.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<AppRouter>(AppRouter.new);
  await $initGetIt(getIt);
  if (!getIt.isRegistered<AppConfigService>()) {
    getIt.registerLazySingleton<AppConfigService>(
      () => AppConfigService(getIt<HttpService>()),
    );
  }
  if (!getIt.isRegistered<AppConfigRepository>()) {
    getIt.registerLazySingleton<AppConfigRepository>(
      () => AppConfigRepository(
        getIt<AppConfigService>(),
        getIt<LocalKeyStorage>(),
      ),
    );
  }
  if (!getIt.isRegistered<AppConfigController>()) {
    getIt.registerLazySingleton<AppConfigController>(
      () => AppConfigController(getIt<AppConfigRepository>()),
    );
  }
  if (!getIt.isRegistered<AppAccessPolicy>()) {
    getIt.registerLazySingleton<AppAccessPolicy>(
      () => getIt<AppConfigController>(),
    );
  }
}
