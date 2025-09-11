// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../cubit/app_cubit.dart' as _i145;
import '../data/datasources/authentication_remote_source.dart' as _i510;
import '../data/models/remote/mapper/error_response_mapper.dart' as _i1015;
import '../errors/exception/mapper/http_request_exception_mapper.dart' as _i806;
import '../network/http_service.dart' as _i944;
import '../utils/preferences/app_preferences.dart' as _i395;
import 'register_module.dart' as _i291;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final registerModule = _$RegisterModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => registerModule.prefs,
    preResolve: true,
  );
  gh.factory<_i944.HttpService>(() => _i944.HttpService());
  gh.factory<_i510.AuthenticationRemoteSource>(
      () => _i510.AuthenticationRemoteSource());
  gh.factory<_i1015.ErrorResponseMapper>(() => _i1015.ErrorResponseMapper());
  gh.factory<_i145.AppCubit>(
      () => _i145.AppCubit(gh<_i510.AuthenticationRemoteSource>()));
  gh.factory<_i806.HttpRequestExceptionMapper>(
      () => _i806.HttpRequestExceptionMapper(gh<_i1015.ErrorResponseMapper>()));
  gh.factory<_i395.AppPreferences>(
      () => _i395.AppPreferences(gh<_i460.SharedPreferences>()));
  return getIt;
}

class _$RegisterModule extends _i291.RegisterModule {}
