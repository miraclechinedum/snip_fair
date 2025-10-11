import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/datasources/remote/base_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment_list.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/availability_schedule.dart';
import 'package:snip_fair/core/domain/entities/bank/bank.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/social.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/domain/entities/stylist_settings/stylist_settings.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/stylist_stats.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_item.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_list.dart';
import 'package:snip_fair/core/domain/params/login_params.dart';
import 'package:snip_fair/core/domain/params/register_params.dart';
import 'package:snip_fair/core/domain/params/schedule_params.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/utils/utils.dart';

class AuthPath {
  // Auth
  static const login = '/login';
  static const registerCustomer = '/register/customer';
  static const registerStylist = '/register/stylist';
  static const forgotPassword = '/forgot-password';
  static const logout = '/user/logout';
  static const user = '/user'; // GET
  static const resendEmailOtp = '/user/resend-email-otp';
  static const verifyEmailOtp = '/user/verify-email-otp';

  //Profile
  static const updatePassword = '/user/password'; //PATCH
  static const platformSetting = '/platform-settings';

  //Stylists
  static const updateBusinessInfo = '/stylist/basic/profile';
  static const updateIdentityInfo = '/stylist/identity';
  static const stylistProfile = '/stylist/profile';
  static const stylistSettings = '/stylist/settings';
  static const stylistPaymentMethods = '/stylist/payment-methods';
  static const updateAvatar = '/stylist/profile/avatar';
  static const updateBanner = '/stylist/profile/banner';
  static const createWork = '/stylist/work'; //POST
  static const workCategories = '/stylist/work/categories'; //GET
  static const workList = '/stylist/work/list'; //GET with Query Params,
  static const banks = '/banks'; //GET with Query Params,
  static const stats = '/stylist/stats'; //GET with Query Params,
  static const availability = '/stylist/appointment/availability';
  static const appointment = '/stylist/appointment';
  static const earnings = '/stylist/earnings';

  //Location
  static const updateLocationConsent = '/user/location/consent';
  static const updateCurrentLocation = '/user/location'; // Patch
}

@LazySingleton()
class SnipFairBackendRemoteSource extends BaseRemoteSource
    implements AuthenticationRepository, ProfileRepository {
  @override
  Future<ApiResult<SimpleResponse>> forgotPassowrd(String email) {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      await client.post<Map<String, dynamic>>(
        AuthPath.forgotPassword,
        data: {'email': email},
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<User>> getUser() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final result = await client.get<Map<String, dynamic>>(AuthPath.user);
      return ApiResult.success(data: User.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<LoginResponse>> login(LoginParams data) {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.login,
        data: data.toJson(),
      );
      return ApiResult.success(data: LoginResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> logout() {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.logout,
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<LoginResponse>> registerCustomer(RegisterParams data) {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.registerCustomer,
        data: data.toJson(),
      );
      return ApiResult.success(data: LoginResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<LoginResponse>> registerStylist(RegisterParams data) {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.registerStylist,
        data: data.toJson(),
      );
      return ApiResult.success(data: LoginResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> resendVerificationEmail(String email) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.resendEmailOtp,
        data: {'email': email},
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.patch<Map<String, dynamic>>(
        AuthPath.updatePassword,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> verifyEmail(String otp) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.verifyEmailOtp,
        data: {'otp': otp},
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateLocationConsent(bool value) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.updateLocationConsent,
        data: {'consent_given': value},
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateUserLocation({
    required num latitude,
    required num longitude,
    required num accuracy,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.patch<Map<String, dynamic>>(
        AuthPath.updateCurrentLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<PlatformSettings>> getPlatformSettings() {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      final result = await client.get<Map<String, dynamic>>(
        AuthPath.platformSetting,
      );
      return ApiResult.success(data: PlatformSettings.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateBusinessInfo({
    required String businessName,
    required String country,
    required String yearsOfExperience,
    required String bio,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.patch<Map<String, dynamic>>(
        AuthPath.updateBusinessInfo,
        data: {
          'business_name': businessName,
          'country': country,
          'years_of_experience': yearsOfExperience,
          'bio': bio,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateIdentityInfo({
    required String documentNumber,
    required String filePath,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);
      final formData = FormData.fromMap({
        'identification_id': documentNumber,
        'identification_file[]': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      await client.post<Map<String, dynamic>>(
        AuthPath.updateIdentityInfo,
        data: formData,
        queryParameters: {'_method': 'PATCH'},
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> createPaymentMethod({
    required String accountNumber,
    required String accountName,
    required String bankName,
    required String routingNumber,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.stylistPaymentMethods,
        data: {
          'account_number': accountNumber,
          'account_name': accountName,
          'bank_name': bankName,
          'routing_number': routingNumber,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> deletePaymentMethod(
    String paymentMethodId,
  ) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.delete<Map<String, dynamic>>(
        '${AuthPath.stylistPaymentMethods}/$paymentMethodId',
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<List<PaymentMethod>>> getPaymentMethods() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<List<dynamic>>(
        AuthPath.stylistPaymentMethods,
      );
      return ApiResult.success(
        data: response.data!
            .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> makePaymentMethodDefault(
    String paymentMethodId,
  ) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        '${AuthPath.stylistPaymentMethods}/$paymentMethodId/default',
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> togglePaymentMethodActive(
    String paymentMethodId,
  ) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        '${AuthPath.stylistPaymentMethods}/$paymentMethodId/toggle',
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updatePaymentMethod({
    required String paymentMethodId,
    required String accountNumber,
    required String accountName,
    required String bankName,
    required String routingNumber,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.patch<Map<String, dynamic>>(
        '${AuthPath.stylistPaymentMethods}/$paymentMethodId',
        data: {
          'account_number': accountNumber,
          'account_name': accountName,
          'bank_name': bankName,
          'routing_number': routingNumber,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<StylistProfileDetails>> getStylistProfile() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.stylistProfile,
      );
      return ApiResult.success(
        data: StylistProfileDetails.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<StylistSettings>> getStylistSettings() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.stylistSettings,
      );
      return ApiResult.success(data: StylistSettings.fromJson(response.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateStylistProfile({
    required String businessName,
    required List<Social> socials,
    required List<String> medias,
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? yearsOfExperience,
    String? bio,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);
      final formData = FormData.fromMap({
        'business_name': businessName,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (country != null) 'country': country,
        if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
        if (bio != null) 'bio': bio,
        'socials': jsonEncode(socials.map((e) => e.toJson()).toList()),
        for (int i = 0; i < medias.length; i++)
          'media[$i]': medias[i].isLocalFilePath
              ? await MultipartFile.fromFile(
                  medias[i],
                  filename: medias[i].split('/').last,
                )
              : medias[i].completeImagePath(),
      });

      await client.post<Map<String, dynamic>>(
        AuthPath.stylistProfile,
        queryParameters: {'_method': 'PATCH'},
        data: formData,
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateStylistSettings(
    StylistSettings settings,
  ) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.put<Map<String, dynamic>>(
        AuthPath.stylistSettings,
        data: settings.toJson(),
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateAvatar(String filePath) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      await client.post<Map<String, dynamic>>(
        AuthPath.updateAvatar,
        data: formData,
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateBanner(String filePath) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      await client.post<Map<String, dynamic>>(
        AuthPath.updateBanner,
        data: formData,
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> createWork({
    required String title,
    required String categoryId,
    required String price,
    required String description,
    required String duration,
    required List<String> images,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);
      final formData = FormData.fromMap({
        'title': title,
        'category_id': categoryId,
        'price': price,
        'duration': duration,
        'description': description,
        'tags': 'all',
        for (int i = 0; i < images.length; i++)
          'media[$i]': images[i].isLocalFilePath
              ? await MultipartFile.fromFile(
                  images[i],
                  filename: images[i].split('/').last,
                )
              : images[i],
      });

      await client.post<Map<String, dynamic>>(
        AuthPath.createWork,
        data: formData,
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> deleteWork(String workId) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.delete<Map<String, dynamic>>(
        '${AuthPath.createWork}/$workId',
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<WorkItem>> fetchWorkById(String workId) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.createWork}/$workId',
      );
      return ApiResult.success(data: WorkItem.fromJson(response.data!));
    });
  }

  @override
  Future<ApiResult<List<WorkCategory>>> fetchWorkCategories() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<List<dynamic>>(
        AuthPath.workCategories,
      );
      return ApiResult.success(
        data: response.data!
            .map(
              (json) => WorkCategory.fromJson(json as Map<String, dynamic>),
            )
            .toList(),
      );
    });
  }

  @override
  Future<ApiResult<WorkList>> fetchWorks({
    String? query,
    String? categoryId,
    String? page,
    int? perPage,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.workList,
        queryParameters: {
          if (query != null) 'query': query,
          if (categoryId != null) 'category_id': categoryId,
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
      );
      return ApiResult.success(
        data: WorkList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateWork(
    String workId, {
    required String title,
    required String categoryId,
    required String price,
    required String description,
    required String duration,
    required List<String> images,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);
      final formData = FormData.fromMap({
        'title': title,
        'category_id': categoryId,
        'price': price,
        'duration': duration,
        'description': description,
        'tags': 'all',
        for (int i = 0; i < images.length; i++)
          'media[$i]': images[i].isLocalFilePath
              ? await MultipartFile.fromFile(
                  images[i],
                  filename: images[i].split('/').last,
                )
              : images[i].completeImagePath(),
      });

      await client.post<Map<String, dynamic>>(
        '${AuthPath.createWork}/$workId',
        data: formData,
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateWorkAvailability(
    String workId, {
    required bool isAvailable,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();

      await client.put<Map<String, dynamic>>(
        '${AuthPath.createWork}/$workId/status',
        data: {
          'is_available': isAvailable,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<List<Bank>>> getBanks() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<List<dynamic>>(
        AuthPath.banks,
      );
      return ApiResult.success(
        data: response.data!
            .map(
              (json) => Bank.fromJson(json as Map<String, dynamic>),
            )
            .toList(),
      );
    });
  }

  @override
  Future<ApiResult<StylistStats>> getStylistStats() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.stats,
      );
      return ApiResult.success(
        data: StylistStats.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<Appointment>> getAppointmentById(String id) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.appointment}/$id',
      );
      return ApiResult.success(
        data: Appointment.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<AppointmentList>> getAppointments({
    String? query,
    String? categoryId,
    String? page,
    int? perPage,
    String? customerId,
    String? portfolioId,
    String? status,
    String? sort,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.appointment}/list',
        queryParameters: {
          if (query != null) 'query': query,
          if (categoryId != null) 'category_id': categoryId,
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
          if (customerId != null) 'customer_id': customerId,
          if (portfolioId != null) 'portfolio_id': portfolioId,
          if (status != null) 'status': status,
          if (sort != null) 'sort': sort,
        },
      );
      return ApiResult.success(
        data: AppointmentList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<AvailabilitySchedule>> getAvailability() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.availability,
      );
      return ApiResult.success(
        data: AvailabilitySchedule.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateAppointment(
    String id, {
    required String variant,
    required String code,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        '${AuthPath.appointment}/$id',
        data: {
          'variant': variant,
          'code': code,
        },
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateAvailability({
    bool? isAvailable,
    List<ScheduleParams>? schedules,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.availability,
        data: {
          if (isAvailable != null) 'is_available': isAvailable,
          if (schedules != null)
            'schedules': schedules.map((e) => e.toJson()).toList(),
        },
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<StylistEarnings>> getEarnings() {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.earnings,
      );
      return ApiResult.success(
        data: StylistEarnings.fromJson(response.data!),
      );
    });
  }
}
