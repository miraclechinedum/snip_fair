import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
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
import 'package:snip_fair/core/domain/params/schedule_params.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';

abstract class ProfileRepository {
  Future<ApiResult<User>> getUser();
  Future<ApiResult<SimpleResponse>> logout();
  Future<ApiResult<SimpleResponse>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<ApiResult<SimpleResponse>> updateLocationConsent(bool value);

  Future<ApiResult<SimpleResponse>> updateUserLocation({
    required num latitude,
    required num longitude,
    required num accuracy,
  });

  Future<ApiResult<PlatformSettings>> getPlatformSettings();

  Future<ApiResult<SimpleResponse>> updateBusinessInfo({
    required String businessName,
    required String country,
    required String yearsOfExperience,
    required String bio,
  });

  Future<ApiResult<SimpleResponse>> updateIdentityInfo({
    required String documentNumber,
    required String filePath,
  });

  Future<ApiResult<StylistProfileDetails>> getStylistProfile();

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
  });

  Future<ApiResult<SimpleResponse>> makePaymentMethodDefault(
    String paymentMethodId,
  );
  Future<ApiResult<SimpleResponse>> togglePaymentMethodActive(
    String paymentMethodId,
  );
  Future<ApiResult<SimpleResponse>> deletePaymentMethod(String paymentMethodId);

  Future<ApiResult<List<PaymentMethod>>> getPaymentMethods();

  Future<ApiResult<SimpleResponse>> createPaymentMethod({
    required String accountNumber,
    required String accountName,
    required String bankName,
    required String routingNumber,
  });

  Future<ApiResult<SimpleResponse>> updatePaymentMethod({
    required String paymentMethodId,
    required String accountNumber,
    required String accountName,
    required String bankName,
    required String routingNumber,
  });

  Future<ApiResult<StylistSettings>> getStylistSettings();

  Future<ApiResult<SimpleResponse>> updateStylistSettings(
    StylistSettings settings,
  );

  Future<ApiResult<SimpleResponse>> updateAvatar(
    String filePath,
  );

  Future<ApiResult<SimpleResponse>> updateBanner(
    String filePath,
  );

  Future<ApiResult<List<WorkCategory>>> fetchWorkCategories();

  Future<ApiResult<WorkList>> fetchWorks({
    String? query,
    String? categoryId,
    String page,
    int perPage,
  });

  Future<ApiResult<SimpleResponse>> createWork({
    required String title,
    required String categoryId,
    required String price,
    required String description,
    required String duration,
    required List<String> images,
  });

  Future<ApiResult<WorkItem>> fetchWorkById(
    String workId,
  );

  Future<ApiResult<SimpleResponse>> updateWork(
    String workId, {
    required String title,
    required String categoryId,
    required String price,
    required String description,
    required String duration,
    required List<String> images,
  });

  Future<ApiResult<SimpleResponse>> updateWorkAvailability(
    String workId, {
    required bool isAvailable,
  });

  Future<ApiResult<SimpleResponse>> deleteWork(String workId);

  Future<ApiResult<List<Bank>>> getBanks();
  Future<ApiResult<StylistStats>> getStylistStats();

  Future<ApiResult<AvailabilitySchedule>> getAvailability();
  Future<ApiResult<SimpleResponse>> updateAvailability({
    bool? isAvailable,
    List<ScheduleParams>? schedules,
  });

  Future<ApiResult<AppointmentList>> getAppointments({
    String? query,
    String? categoryId,
    String? page,
    int? perPage,
    String? customerId,
    String? portfolioId,
    String? status,
    String? sort,
  });
  Future<ApiResult<Appointment>> getAppointmentById(String id);
  Future<ApiResult<SimpleResponse>> updateAppointment(
    String id, {
    required String variant,
    required String code,
  });

  Future<ApiResult<StylistEarnings>> getEarnings();
}

@Injectable(as: ProfileRepository)
class ProfileRepoImpl implements ProfileRepository {
  ProfileRepoImpl(this._localKeyStorage, this._remoteSource);

  final LocalKeyStorage _localKeyStorage;
  final SnipFairBackendRemoteSource _remoteSource;

  @override
  Future<ApiResult<User>> getUser() async {
    final result = await _remoteSource.getUser();
    return result.map(
      success: (data) {
        _localKeyStorage.saveCurrentUser(data.data);
        return data;
      },
      failure: (f) => f,
    );
  }

  @override
  Future<ApiResult<SimpleResponse>> logout() async {
    final result = await _remoteSource.logout();
    await _localKeyStorage.clearData();
    return result;
  }

  @override
  Future<ApiResult<SimpleResponse>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _remoteSource.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateLocationConsent(bool value) =>
      _remoteSource.updateLocationConsent(value);

  @override
  Future<ApiResult<SimpleResponse>> updateUserLocation({
    required num latitude,
    required num longitude,
    required num accuracy,
  }) =>
      _remoteSource.updateUserLocation(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );

  @override
  Future<ApiResult<PlatformSettings>> getPlatformSettings() =>
      _remoteSource.getPlatformSettings();

  @override
  Future<ApiResult<SimpleResponse>> updateBusinessInfo({
    required String businessName,
    required String country,
    required String yearsOfExperience,
    required String bio,
  }) =>
      _remoteSource.updateBusinessInfo(
        businessName: businessName,
        country: country,
        yearsOfExperience: yearsOfExperience,
        bio: bio,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateIdentityInfo({
    required String documentNumber,
    required String filePath,
  }) =>
      _remoteSource.updateIdentityInfo(
        documentNumber: documentNumber,
        filePath: filePath,
      );

  @override
  Future<ApiResult<SimpleResponse>> createPaymentMethod({
    required String accountNumber,
    required String accountName,
    required String bankName,
    required String routingNumber,
  }) =>
      _remoteSource.createPaymentMethod(
        accountNumber: accountNumber,
        accountName: accountName,
        bankName: bankName,
        routingNumber: routingNumber,
      );

  @override
  Future<ApiResult<SimpleResponse>> deletePaymentMethod(
    String paymentMethodId,
  ) =>
      _remoteSource.deletePaymentMethod(paymentMethodId);

  @override
  Future<ApiResult<List<PaymentMethod>>> getPaymentMethods() =>
      _remoteSource.getPaymentMethods();

  @override
  Future<ApiResult<StylistProfileDetails>> getStylistProfile() =>
      _remoteSource.getStylistProfile();

  @override
  Future<ApiResult<StylistSettings>> getStylistSettings() =>
      _remoteSource.getStylistSettings();

  @override
  Future<ApiResult<SimpleResponse>> makePaymentMethodDefault(
    String paymentMethodId,
  ) =>
      _remoteSource.makePaymentMethodDefault(paymentMethodId);

  @override
  Future<ApiResult<SimpleResponse>> togglePaymentMethodActive(
    String paymentMethodId,
  ) =>
      _remoteSource.togglePaymentMethodActive(paymentMethodId);

  @override
  Future<ApiResult<SimpleResponse>> updatePaymentMethod({
    required String paymentMethodId,
    required String accountNumber,
    required String accountName,
    required String bankName,
    required String routingNumber,
  }) =>
      _remoteSource.updatePaymentMethod(
        paymentMethodId: paymentMethodId,
        accountNumber: accountNumber,
        accountName: accountName,
        bankName: bankName,
        routingNumber: routingNumber,
      );

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
  }) =>
      _remoteSource.updateStylistProfile(
        businessName: businessName,
        socials: socials,
        medias: medias,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        country: country,
        yearsOfExperience: yearsOfExperience,
        bio: bio,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateStylistSettings(
    StylistSettings settings,
  ) =>
      _remoteSource.updateStylistSettings(settings);

  @override
  Future<ApiResult<SimpleResponse>> updateAvatar(String filePath) =>
      _remoteSource.updateAvatar(filePath);

  @override
  Future<ApiResult<SimpleResponse>> updateBanner(String filePath) =>
      _remoteSource.updateBanner(filePath);

  @override
  Future<ApiResult<SimpleResponse>> createWork({
    required String title,
    required String categoryId,
    required String price,
    required String description,
    required String duration,
    required List<String> images,
  }) =>
      _remoteSource.createWork(
        title: title,
        categoryId: categoryId,
        price: price,
        description: description,
        duration: duration,
        images: images,
      );

  @override
  Future<ApiResult<SimpleResponse>> deleteWork(String workId) =>
      _remoteSource.deleteWork(workId);

  @override
  Future<ApiResult<WorkItem>> fetchWorkById(String workId) =>
      _remoteSource.fetchWorkById(workId);

  @override
  Future<ApiResult<List<WorkCategory>>> fetchWorkCategories() =>
      _remoteSource.fetchWorkCategories();

  @override
  Future<ApiResult<WorkList>> fetchWorks({
    String? query,
    String? categoryId,
    String? page,
    int? perPage,
  }) =>
      _remoteSource.fetchWorks(
        query: query,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateWork(
    String workId, {
    required String title,
    required String categoryId,
    required String price,
    required String description,
    required String duration,
    required List<String> images,
  }) =>
      _remoteSource.updateWork(
        workId,
        title: title,
        categoryId: categoryId,
        price: price,
        description: description,
        duration: duration,
        images: images,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateWorkAvailability(
    String workId, {
    required bool isAvailable,
  }) =>
      _remoteSource.updateWorkAvailability(workId, isAvailable: isAvailable);

  @override
  Future<ApiResult<List<Bank>>> getBanks() => _remoteSource.getBanks();

  @override
  Future<ApiResult<StylistStats>> getStylistStats() =>
      _remoteSource.getStylistStats();

  @override
  Future<ApiResult<Appointment>> getAppointmentById(String id) =>
      _remoteSource.getAppointmentById(id);

  @override
  Future<ApiResult<AppointmentList>> getAppointments(
          {String? query,
          String? categoryId,
          String? page,
          int? perPage,
          String? customerId,
          String? portfolioId,
          String? status,
          String? sort}) =>
      _remoteSource.getAppointments(
        query: query,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
        customerId: customerId,
        portfolioId: portfolioId,
        status: status,
        sort: sort,
      );

  @override
  Future<ApiResult<AvailabilitySchedule>> getAvailability() =>
      _remoteSource.getAvailability();
  @override
  Future<ApiResult<SimpleResponse>> updateAppointment(String id,
          {required String variant, required String code}) =>
      _remoteSource.updateAppointment(id, variant: variant, code: code);

  @override
  Future<ApiResult<SimpleResponse>> updateAvailability(
          {bool? isAvailable, List<ScheduleParams>? schedules}) =>
      _remoteSource.updateAvailability(
        isAvailable: isAvailable,
        schedules: schedules,
      );

  @override
  Future<ApiResult<StylistEarnings>> getEarnings() =>
      _remoteSource.getEarnings();
}
