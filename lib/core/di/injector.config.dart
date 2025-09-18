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

import '../../features/authentication/forgot_password/cubit/forgot_password_cubit.dart'
    as _i368;
import '../../features/authentication/login/cubit/login_cubit.dart' as _i553;
import '../../features/authentication/signup/cubit/signup_cubit.dart' as _i643;
import '../../features/authentication/verify_email/cubit/verify_email_cubit.dart'
    as _i97;
import '../cubit/app_cubit.dart' as _i145;
import '../data/datasources/remote/snip_fair_backend_remote_source.dart'
    as _i637;
import '../data/models/remote/mapper/error_response_mapper.dart' as _i1015;
import '../data/repositories/authentication_repository.dart' as _i345;
import '../data/repositories/profile_repository.dart' as _i990;
import '../errors/exception/mapper/http_request_exception_mapper.dart' as _i806;
import '../network/http_service.dart' as _i944;
import '../services/location_service.dart' as _i669;
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
  gh.factory<_i1015.ErrorResponseMapper>(() => _i1015.ErrorResponseMapper());
  gh.lazySingleton<_i637.SnipFairBackendRemoteSource>(
      () => _i637.SnipFairBackendRemoteSource());
  gh.lazySingleton<_i669.LocationService>(() => _i669.LocationService());
  gh.factory<_i806.HttpRequestExceptionMapper>(
      () => _i806.HttpRequestExceptionMapper(gh<_i1015.ErrorResponseMapper>()));
  gh.factory<_i395.LocalKeyStorage>(
      () => _i395.LocalKeyStorage(gh<_i460.SharedPreferences>()));
  gh.factory<_i345.AuthenticationRepository>(() => _i345.AuthenticationRepoImpl(
        gh<_i395.LocalKeyStorage>(),
        gh<_i637.SnipFairBackendRemoteSource>(),
      ));
  gh.factory<_i990.ProfileRepository>(() => _i990.ProfileRepoImpl(
        gh<_i395.LocalKeyStorage>(),
        gh<_i637.SnipFairBackendRemoteSource>(),
      ));
  gh.factory<_i145.AppCubit>(
      () => _i145.AppCubit(gh<_i345.AuthenticationRepository>()));
  gh.factory<_i368.ForgotPasswordCubit>(
      () => _i368.ForgotPasswordCubit(gh<_i345.AuthenticationRepository>()));
  gh.factory<_i643.SignupCubit>(
      () => _i643.SignupCubit(gh<_i345.AuthenticationRepository>()));
  gh.factory<_i97.VerifyEmailCubit>(
      () => _i97.VerifyEmailCubit(gh<_i345.AuthenticationRepository>()));
  gh.factory<_i553.LoginCubit>(
      () => _i553.LoginCubit(gh<_i345.AuthenticationRepository>()));
  return getIt;
}

class _$RegisterModule extends _i291.RegisterModule {}
