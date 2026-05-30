import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/domain/entities/bank/bank.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/domain/params/login_params.dart';
import 'package:snip_fair/core/domain/params/register_params.dart';
import 'package:snip_fair/core/domain/params/schedule_params.dart';
import 'package:snip_fair/core/domain/entities/tip/tip_response.dart';
import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_item.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_list.dart';
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/dispute_list/dispute_list.dart';
import 'package:snip_fair/core/domain/entities/stylist_list/stylist_list.dart';
import 'package:snip_fair/core/data/datasources/remote/base_remote_source.dart';
import 'package:snip_fair/core/data/repositories/authentication_repository.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment_list.dart';
import 'package:snip_fair/core/domain/entities/like_response/like_response.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/stylist_stats.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/domain/entities/customer_stats/customer_stats.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/social.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/customer_wallet.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/stylist_settings/stylist_settings.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message_list.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/preferences.dart';
import 'package:snip_fair/core/domain/entities/notifications_list/notifications_list.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/notifications.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';
import 'package:snip_fair/core/domain/entities/payfast_payment_data/payfast_payment_data.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/availability_schedule.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio_list.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile_details.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment_list.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';

class AuthPath {
  // Auth
  static const login = '/login';
  static const loginWithGoogle = '/login/google';
  static const registerCustomer = '/register/customer';
  static const registerStylist = '/register/stylist';
  static const forgotPassword = '/forgot-password';
  static const logout = '/user/logout';
  static const user = '/user'; // GET
  static const resendEmailOtp = '/user/resend-email-otp';
  static const verifyEmailOtp = '/user/verify-email-otp';

  //Costumer
  static const customerStylists = '/customer/stylist';
  static const customerProfile = '/customer/profile';
  static const customerStats = '/customer/stats';
  static const portfolio = '/customer/portfolio';
  static const toggleLike = '/like/toggle';
  static const customerAppointment = '/customer/appointment';
  static const customerPreferences = '/customer/preferences';
  static const customerBilling = '/customer/billing';
  static const customerNotificationSettings = '/customer/notification/settings';

  // Chats
  static const conversations = '/conversations';
  static const disputes = '/dispute/list';

  //Wallet
  static const customerWallet = '/wallet';
  static const customerWalletTransactions = '/wallet/transactions';
  static const withdrawFunds = '/wallet/withdraw';

  //Payment
  static const initializePayfastDeposit = '/payment/initiate/payfast';

  //Profile
  static const updatePassword = '/user/password'; //PATCH
  static const platformSetting = '/platform-settings';
  static const updateUser = '/user';

  //Stylists
  static const updateBusinessInfo = '/stylist/basic/profile';
  static const updateIdentityInfo = '/stylist/identity';
  static const stylistProfile = '/stylist/profile';
  static const stylistSettings = '/stylist/settings';
  static const stylistPaymentMethods = '/stylist/payment-methods';
  static const updateAvatar = '/stylist/profile/avatar';
  static const updateBanner = '/stylist/profile/banner';
  static const createWork = '/stylist/work'; //POST
  static const workCategories = '/categories'; //GET
  static const workList = '/stylist/work/list'; //GET with Query Params,
  static const banks = '/banks'; //GET with Query Params,
  static const stats = '/stylist/stats'; //GET with Query Params,
  static const availability = '/stylist/appointment/availability';
  static const stylistAppointment = '/stylist/appointment';
  static const earnings = '/stylist/earnings';

  //Location
  static const updateLocationConsent = '/user/location/consent';
  static const updateCurrentLocation = '/user/location'; // Patch

  // Payment Requests
  static const paymentRequests = '/payment-requests';
}

@LazySingleton()
class SnipFairBackendRemoteSource extends BaseRemoteSource
    implements AuthenticationRepository, ProfileRepository, AppointmentRepository {
  /// Helper method to get a Dio client with retry interceptor for GET requests
  Dio _clientWithRetry({bool requireAuth = true, bool optionalAuth = false}) {
    final client = getIt<HttpService>()
        .client(requireAuth: requireAuth, optionalAuth: optionalAuth);
    client.interceptors.add(
      RetryInterceptor(
        dio: client,
        logPrint: print,
        retries: 5,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );
    return client;
  }

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
      final client = _clientWithRetry();
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
      final client = _clientWithRetry(requireAuth: false);
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
    required String photoPath,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);
      final formData = FormData.fromMap({
        'identification_id': documentNumber,
        'identification_proof': await MultipartFile.fromFile(
          photoPath,
          filename: photoPath.split('/').last,
        ),
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
      final client = _clientWithRetry();
      final response = await client.get<List<dynamic>>(
        AuthPath.stylistPaymentMethods,
      );
      return ApiResult.success(
        data: response.data!.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>)).toList(),
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
      final client = _clientWithRetry();
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
      final client = _clientWithRetry();
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
    String? gender,
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
        if (gender != null) 'gender': gender,
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
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.createWork}/$workId',
      );
      return ApiResult.success(data: WorkItem.fromJson(response.data!));
    });
  }

  @override
  Future<ApiResult<List<WorkCategory>>> fetchWorkCategories() {
    return run(() async {
      final client = _clientWithRetry(requireAuth: false);
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
      final client = _clientWithRetry();
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
      final client = _clientWithRetry();
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
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.stats,
      );
      return ApiResult.success(
        data: StylistStats.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<StylistAppointment>> getStylistAppointmentById(String id) {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.stylistAppointment}/$id',
      );
      return ApiResult.success(
        data: StylistAppointment.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<StylistAppointmentList>> getStylistAppointments({
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
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.stylistAppointment}/list',
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
        data: StylistAppointmentList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<AvailabilitySchedule>> getAvailability() {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.availability,
      );
      return ApiResult.success(
        data: AvailabilitySchedule.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateStylistAppointment(
    String id, {
    required String verdict,
    String? code,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        '${AuthPath.stylistAppointment}/$id',
        data: {
          'verdict': verdict,
          if (code != null) 'code': code,
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
          if (schedules != null) 'schedules': schedules.map((e) => e.toJson()).toList(),
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
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.earnings,
      );
      return ApiResult.success(
        data: StylistEarnings.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateUser({
    bool? useLocation,
    String? address,
    String? fcmToken,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.patch<Map<String, dynamic>>(
        AuthPath.updateUser,
        data: {
          if (useLocation != null) 'use_location': useLocation,
          if (address != null) 'country': address,
          if (fcmToken != null) 'firebase_device_token': fcmToken,
        },
      );
      return ApiResult.success(data: SimpleResponse.fromJson({}));
    });
  }

  @override
  Future<ApiResult<CustomerProfileDetails>> getCustomerProfile() {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.customerProfile,
      );
      return ApiResult.success(
        data: CustomerProfileDetails.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<CustomerStats>> getCustomerStats() {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.customerStats,
      );
      return ApiResult.success(
        data: CustomerStats.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SellerDetails>> customerFetchStylistById(String id) {
    return run(() async {
      final client = _clientWithRetry(optionalAuth: true);
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.customerStylists}/$id',
      );
      return ApiResult.success(
        data: SellerDetails.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<StylistList>> customerFetchStylists({
    String? query,
    String? categoryId,
    String? page,
    String? perPage,
    String? sort,
    bool? favourite,
    bool? topRated,
    bool? online,
    bool? highestRated,
    bool? lowestPrice,
    String? minPrice,
    String? maxPrice,
  }) {
    return run(() async {
      final client = _clientWithRetry(optionalAuth: true);
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.customerStylists}/list',
        queryParameters: {
          if (query != null) 'query': query,
          if (categoryId != null) 'category_id': categoryId,
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
          if (sort != null) 'sort': sort,
          if (favourite != null) 'favourite': favourite,
          if (topRated != null) 'top_rated': topRated,
          if (online != null) 'online': online,
          if (highestRated != null) 'highest_rated': highestRated,
          if (lowestPrice != null) 'lowest_price': lowestPrice,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
        },
      );
      return ApiResult.success(
        data: StylistList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SellerPortfolioList>> customerFetchPortfolioList({
    String? query,
    String? categoryId,
    String? stylistId,
    String? page,
    String? perPage,
    String? sort,
    bool? favourite,
    bool? topRated,
    bool? online,
    bool? highestRated,
    bool? lowestPrice,
    String? minPrice,
    String? maxPrice,
  }) {
    return run(() async {
      final client = _clientWithRetry(optionalAuth: true);
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.portfolio}/list',
        queryParameters: {
          if (query != null) 'query': query,
          if (categoryId != null) 'category_id': categoryId,
          if (stylistId != null) 'stylist_id': stylistId,
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
          if (sort != null) 'sort': sort,
          if (favourite != null) 'favourite': favourite,
          if (topRated != null) 'top_rated': topRated,
          if (online != null) 'online': online,
          if (highestRated != null) 'highest_rated': highestRated,
          if (lowestPrice != null) 'lowest_price': lowestPrice,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
        },
      );
      return ApiResult.success(
        data: SellerPortfolioList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<CustomerWallet>> getWallet() {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.customerWallet,
      );
      return ApiResult.success(
        data: CustomerWallet.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<CustomerWalletTransactionList>> getWalletTransactions({
    String? page,
    int? perPage = 10,
  }) {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.customerWalletTransactions,
        queryParameters: {
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
      );
      return ApiResult.success(
        data: CustomerWalletTransactionList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<PayfastPaymentData>> initialisePayfastDeposit({
    required String type,
    required String amount,
    String? email,
    String? firstName,
    String? lastName,
    String? portfolioId,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.post<Map<String, dynamic>>(
        AuthPath.initializePayfastDeposit,
        data: {
          'type': type,
          'amount': amount,
          if (email != null) 'email': email,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (portfolioId != null) 'portfolio_id': portfolioId,
        },
      );
      return ApiResult.success(
        data: PayfastPaymentData.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<LikeResponse>> toggleLike({
    required String type,
    required String typeId,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.post<Map<String, dynamic>>(
        AuthPath.toggleLike,
        data: {
          'type': type,
          'type_id': typeId,
        },
      );
      return ApiResult.success(data: LikeResponse.fromJson(response.data!));
    });
  }

  @override
  Future<ApiResult<SellerPortfolio>> customerFetchPortfolioById({String? id}) {
    return run(() async {
      final client = _clientWithRetry(optionalAuth: true);
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.portfolio}/$id',
      );
      return ApiResult.success(
        data: SellerPortfolio.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<CustomerAppointment>> createAppointment({
    required String portfolioId,
    required String date,
    required String time,
    String? note,
    String? address,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.post<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/book',
        data: {
          'portfolio_id': portfolioId,
          'selected_date': date,
          'selected_time': time,
          if (address != null) 'address': address,
          if (note != null) 'extra': note,
        },
      );
      return ApiResult.success(
        data: CustomerAppointment.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<CustomerAppointment>> getCustomerAppointmentById(
    String appointmentId,
  ) {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/$appointmentId',
      );
      return ApiResult.success(
        data: CustomerAppointment.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<CustomerAppointmentList>> getCustomerAppointments({
    String? page,
    String? perPage,
  }) {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/list',
        queryParameters: {
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
      );
      return ApiResult.success(
        data: CustomerAppointmentList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<List<ChatConversation>>> getChatConversations() {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<List<dynamic>>(
        AuthPath.conversations,
      );
      return ApiResult.success(
        data: response.data!
            .map<ChatConversation>(
              (json) => ChatConversation.fromJson(json as Map<String, dynamic>),
            )
            .toList(),
      );
    });
  }

  @override
  Future<ApiResult<ChatMessageList>> getChatMessages(String conversationId) {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.conversations}/$conversationId/messages',
      );
      return ApiResult.success(
        data: ChatMessageList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        '${AuthPath.conversations}/$conversationId/messages/$messageId/read',
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> sendMessage({
    required String conversationId,
    required String text,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        '${AuthPath.conversations}/$conversationId/messages',
        data: {
          'text': text,
        },
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<ChatConversation>> startConversation({
    required String recipientId,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.post<Map<String, dynamic>>(
        AuthPath.conversations,
        data: {
          'recipient_id': recipientId,
        },
      );
      return ApiResult.success(
        data: ChatConversation.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> disputeCustomerAppointment(
    String id, {
    required String comment,
    required List<String> images,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final formData = FormData.fromMap({
        'comment': comment,
        for (int i = 0; i < images.length; i++)
          'images[$i]': await MultipartFile.fromFile(
            images[i],
            filename: images[i].split('/').last,
          ),
      });
      await client.post<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/$id/dispute',
        data: formData,
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> reviewCustomerAppointment(
    String id, {
    required int rating,
    String? comment,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();

      await client.post<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/$id/review',
        data: {
          'rating': rating,
          if (comment != null) 'review': comment,
        },
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<TipResponse>> tipCustomerAppointment(
    String id, {
    required double amount,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();

      final response = await client.post<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/$id/tip',
        data: {'amount': amount},
      );
      return ApiResult.success(
        data: TipResponse.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerAppointment(
    String id, {
    required String verdict,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();

      await client.patch<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/$id',
        data: {
          'verdict': verdict,
        },
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<DisputeList>> getDisputes() {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        AuthPath.disputes,
      );
      return ApiResult.success(
        data: DisputeList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerProfile({
    String? avatar,
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? yearsOfExperience,
    String? bio,
    String? gender,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);

      final formData = FormData.fromMap({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (country != null) 'country': country,
        if (bio != null) 'bio': bio,
        if (gender != null) 'gender': gender,
        if (avatar != null)
          'avatar': avatar.isLocalFilePath
              ? await MultipartFile.fromFile(
                  avatar,
                  filename: avatar.split('/').last,
                )
              : avatar.completeImagePath(),
      });

      await client.post<Map<String, dynamic>>(
        AuthPath.customerProfile,
        queryParameters: {'_method': 'PATCH'},
        data: formData,
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> requestPayout(
    String paymentMethodId,
    double amount,
  ) {
    return run(() async {
      final client = getIt<HttpService>().client();

      await client.post<Map<String, dynamic>>(
        AuthPath.withdrawFunds,
        data: {'amount': amount.toString(), 'method': paymentMethodId},
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> deleteAccount() {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.delete<Map<String, dynamic>>(
        AuthPath.user,
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<NotificationsList>> getNotifications({
    String? page,
    int? perPage,
  }) {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.user}/notifications',
        queryParameters: {
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage.toString(),
        },
      );
      return ApiResult.success(
        data: NotificationsList.fromJson(response.data!),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> disputeStylistAppointment(
    String id, {
    required String comment,
    required List<String> images,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);

      final formData = FormData.fromMap({
        'comment': comment,
        for (int i = 0; i < images.length; i++)
          'images[$i]': await MultipartFile.fromFile(
            images[i],
            filename: images[i].split('/').last,
          ),
      });

      await client.post<Map<String, dynamic>>(
        '${AuthPath.stylistAppointment}/$id/dispute',
        data: formData,
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> submitAppointmentProof(
    String id, {
    required String comment,
    required List<String> images,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(isFormDataRequest: true);

      final formData = FormData.fromMap({
        'comment': comment,
        for (int i = 0; i < images.length; i++)
          'images[$i]': await MultipartFile.fromFile(
            images[i],
            filename: images[i].split('/').last,
          ),
      });

      await client.post<Map<String, dynamic>>(
        '${AuthPath.stylistAppointment}/$id/proof',
        data: formData,
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<LoginResponse>> loginWithGoogle({
    required String accessToken,
    required String role,
    required String device,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client(requireAuth: false);
      final result = await client.post<Map<String, dynamic>>(
        AuthPath.loginWithGoogle,
        data: {
          'access_token': accessToken,
          'role': role,
          'device_name': device,
        },
      );

      return ApiResult.success(data: LoginResponse.fromJson(result.data!));
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> markNotificationAsRead(
    String notificationId,
  ) async {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        '${AuthPath.user}/notifications/$notificationId/read',
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerBillingInfo({
    required String name,
    required String email,
    required String city,
    required String zipCode,
    required String location,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.customerBilling,
        queryParameters: {
          '_method': 'PATCH',
        },
        data: {
          'billing_name': name,
          'billing_email': email,
          'billing_city': city,
          'billing_zip': zipCode,
          'billing_location': location,
        },
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerNotificationSettings(
    Notifications prefs,
  ) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.customerNotificationSettings,
        queryParameters: {
          '_method': 'PATCH',
        },
        data: prefs.toJson()
          ..remove('updatedAt')
          ..remove('createdAt')
          ..remove('_id')
          ..remove('user_id'),
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerPreferences(
    Preferences prefs,
  ) {
    return run(() async {
      final client = getIt<HttpService>().client();
      await client.post<Map<String, dynamic>>(
        AuthPath.customerPreferences,
        queryParameters: {
          '_method': 'PATCH',
        },
        data: prefs.toJson()
          ..remove('updatedAt')
          ..remove('createdAt')
          ..remove('_id')
          ..remove('user_id'),
      );
      return ApiResult.success(
        data: SimpleResponse.fromJson({}),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Payment Request methods
  // ---------------------------------------------------------------------------

  @override
  Future<ApiResult<PaymentRequest>> createPaymentRequest({
    required int recipientId,
    required String title,
    required List<Map<String, dynamic>> items,
    String? description,
    int? appointmentId,
    int? expiresInHours,
  }) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.post<Map<String, dynamic>>(
        AuthPath.paymentRequests,
        data: {
          'recipient_id': recipientId,
          'title': title,
          if (description != null) 'description': description,
          'items': items,
          if (appointmentId != null) 'appointment_id': appointmentId,
          if (expiresInHours != null) 'expires_in_hours': expiresInHours,
        },
      );
      return ApiResult.success(
        data: PaymentRequest.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        ),
      );
    });
  }

  @override
  Future<ApiResult<PaymentRequest>> getPaymentRequest(int id) {
    return run(() async {
      final client = _clientWithRetry();
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.paymentRequests}/$id',
      );
      // ignore: avoid_print
      print('PaymentRequest response: ${response.data}');
      return ApiResult.success(
        data: PaymentRequest.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        ),
      );
    });
  }

  @override
  Future<ApiResult<PaymentRequest>> respondToPaymentRequest(
    int id,
    String action,
  ) {
    return run(() async {
      final client = getIt<HttpService>().client();
      final response = await client.post<Map<String, dynamic>>(
        '${AuthPath.paymentRequests}/$id/$action',
      );
      return ApiResult.success(
        data: PaymentRequest.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        ),
      );
    });
  }
}
