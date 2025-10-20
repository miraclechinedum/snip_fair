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

import '../../features/account/change_password/cubit/change_password_cubit.dart'
    as _i902;
import '../../features/account/customer/personal_details/cubit/customer_personal_details_cubit.dart'
    as _i34;
import '../../features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart'
    as _i1025;
import '../../features/account/seller/availability/cubit/seller_availability_schedule_cubit.dart'
    as _i735;
import '../../features/account/seller/earnings/cubit/earnings_cubit.dart'
    as _i759;
import '../../features/account/seller/payment_methods/cubit/seller_payment_methods_cubit.dart'
    as _i485;
import '../../features/account/seller/personal_details/cubit/seller_personal_details_cubit.dart'
    as _i570;
import '../../features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart'
    as _i762;
import '../../features/account/seller/work/cubit/seller_works_cubit.dart'
    as _i159;
import '../../features/appointments/customer_appointments/cubit/customer_appointments_cubit.dart'
    as _i438;
import '../../features/appointments/stylist_appointments/cubit/seller_appoint_mgt_cubit.dart'
    as _i329;
import '../../features/appointments/stylist_appointments/details/cubit/seller_appointment_details_cubit.dart'
    as _i368;
import '../../features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart'
    as _i400;
import '../../features/authentication/forgot_password/cubit/forgot_password_cubit.dart'
    as _i368;
import '../../features/authentication/login/cubit/login_cubit.dart' as _i553;
import '../../features/authentication/signup/cubit/signup_cubit.dart' as _i643;
import '../../features/authentication/verify_email/cubit/verify_email_cubit.dart'
    as _i97;
import '../../features/conversations/cubit/conversations_cubit.dart' as _i42;
import '../../features/disputes/cubit/disputes_cubit.dart' as _i455;
import '../../features/explore/cubit/explore_cubit.dart' as _i561;
import '../../features/favorites/cubit/customer_favorites_cubit.dart' as _i200;
import '../../features/stylists/onboard/cubit/stylist_onboard_cubit.dart'
    as _i570;
import '../../features/stylists/search/cubit/search_cubit.dart' as _i187;
import '../../features/stylists/stylist_profile/cubit/stylist_seller_details_cubit.dart'
    as _i552;
import '../data/datasources/remote/snip_fair_backend_remote_source.dart'
    as _i637;
import '../data/models/remote/mapper/error_response_mapper.dart' as _i1015;
import '../data/repositories/appointment_repository.dart' as _i939;
import '../data/repositories/authentication_repository.dart' as _i345;
import '../data/repositories/profile_repository.dart' as _i990;
import '../errors/exception/mapper/http_request_exception_mapper.dart' as _i806;
import '../network/http_service.dart' as _i944;
import '../presentation/cubit/app_cubit.dart' as _i782;
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
  gh.factory<_i939.AppointmentRepository>(
      () => _i939.AppointmentRepoImpl(gh<_i637.SnipFairBackendRemoteSource>()));
  gh.factory<_i552.StylistSellerDetailsCubit>(
      () => _i552.StylistSellerDetailsCubit(gh<_i939.AppointmentRepository>()));
  gh.factory<_i187.SearchCubit>(
      () => _i187.SearchCubit(gh<_i939.AppointmentRepository>()));
  gh.factory<_i329.SellerAppointMgtCubit>(
      () => _i329.SellerAppointMgtCubit(gh<_i939.AppointmentRepository>()));
  gh.factory<_i368.SellerAppointmentDetailsCubit>(() =>
      _i368.SellerAppointmentDetailsCubit(gh<_i939.AppointmentRepository>()));
  gh.factory<_i400.UpdateCreateAppointmentCubit>(() =>
      _i400.UpdateCreateAppointmentCubit(gh<_i939.AppointmentRepository>()));
  gh.factory<_i438.CustomerAppointmentsCubit>(
      () => _i438.CustomerAppointmentsCubit(gh<_i939.AppointmentRepository>()));
  gh.factory<_i200.CustomerFavoritesCubit>(
      () => _i200.CustomerFavoritesCubit(gh<_i939.AppointmentRepository>()));
  gh.factory<_i561.ExploreCubit>(
      () => _i561.ExploreCubit(gh<_i939.AppointmentRepository>()));
  gh.factory<_i345.AuthenticationRepository>(() => _i345.AuthenticationRepoImpl(
        gh<_i395.LocalKeyStorage>(),
        gh<_i637.SnipFairBackendRemoteSource>(),
      ));
  gh.factory<_i990.ProfileRepository>(() => _i990.ProfileRepoImpl(
        gh<_i395.LocalKeyStorage>(),
        gh<_i637.SnipFairBackendRemoteSource>(),
      ));
  gh.factory<_i368.ForgotPasswordCubit>(
      () => _i368.ForgotPasswordCubit(gh<_i345.AuthenticationRepository>()));
  gh.factory<_i643.SignupCubit>(
      () => _i643.SignupCubit(gh<_i345.AuthenticationRepository>()));
  gh.factory<_i97.VerifyEmailCubit>(
      () => _i97.VerifyEmailCubit(gh<_i345.AuthenticationRepository>()));
  gh.factory<_i553.LoginCubit>(
      () => _i553.LoginCubit(gh<_i345.AuthenticationRepository>()));
  gh.factory<_i570.StylistOnboardCubit>(
      () => _i570.StylistOnboardCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i455.DisputesCubit>(
      () => _i455.DisputesCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i42.ConversationsCubit>(
      () => _i42.ConversationsCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i570.SellerPersonalDetailsCubit>(
      () => _i570.SellerPersonalDetailsCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i759.EarningsCubit>(
      () => _i759.EarningsCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i159.SellerWorksCubit>(
      () => _i159.SellerWorksCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i762.SellerProfileMgtCubit>(
      () => _i762.SellerProfileMgtCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i735.SellerAvailabilityScheduleCubit>(() =>
      _i735.SellerAvailabilityScheduleCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i485.SellerPaymentMethodsCubit>(
      () => _i485.SellerPaymentMethodsCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i902.ChangePasswordCubit>(
      () => _i902.ChangePasswordCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i34.CustomerPersonalDetailsCubit>(
      () => _i34.CustomerPersonalDetailsCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i1025.CustomerProfileMgtCubit>(
      () => _i1025.CustomerProfileMgtCubit(gh<_i990.ProfileRepository>()));
  gh.factory<_i782.AppCubit>(
      () => _i782.AppCubit(gh<_i990.ProfileRepository>()));
  return getIt;
}

class _$RegisterModule extends _i291.RegisterModule {}
