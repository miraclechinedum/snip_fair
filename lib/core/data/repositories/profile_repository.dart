import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/domain/entities/availability_schedule/availability_schedule.dart';
import 'package:snip_fair/core/domain/entities/bank/bank.dart';
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message_list.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile_details.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/notifications.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/preferences.dart';
import 'package:snip_fair/core/domain/entities/customer_stats/customer_stats.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet/customer_wallet.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/core/domain/entities/dispute_list/dispute_list.dart';
import 'package:snip_fair/core/domain/entities/notifications_list/notifications_list.dart';
import 'package:snip_fair/core/domain/entities/payfast_payment_data/payfast_payment_data.dart';
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
    required String photoPath,
  });

  Future<ApiResult<StylistProfileDetails>> getStylistProfile();
  Future<ApiResult<CustomerProfileDetails>> getCustomerProfile();

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
  });

  Future<ApiResult<SimpleResponse>> updateCustomerProfile({
    String? avatar,
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? yearsOfExperience,
    String? bio,
    String? gender,
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
    String? page,
    int? perPage,
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
  Future<ApiResult<CustomerStats>> getCustomerStats();

  Future<ApiResult<AvailabilitySchedule>> getAvailability();
  Future<ApiResult<SimpleResponse>> updateAvailability({
    bool? isAvailable,
    List<ScheduleParams>? schedules,
  });

  Future<ApiResult<StylistEarnings>> getEarnings();

  Future<ApiResult<SimpleResponse>> updateUser({
    bool? useLocation,
    String? address,
    String? fcmToken,
  });

  Future<ApiResult<CustomerWallet>> getWallet();

  Future<ApiResult<CustomerWalletTransactionList>> getWalletTransactions({
    String? page,
    int? perPage,
  });

  Future<ApiResult<PayfastPaymentData>> initialisePayfastDeposit({
    required String type,
    required String amount,
    String? email,
    String? firstName,
    String? lastName,
    String? portfolioId,
  });

  Future<ApiResult<List<ChatConversation>>> getChatConversations();

  Future<ApiResult<ChatMessageList>> getChatMessages(String conversationId);

  Future<ApiResult<SimpleResponse>> sendMessage({
    required String conversationId,
    required String text,
  });

  Future<ApiResult<ChatConversation>> startConversation({
    required String recipientId,
  });

  Future<ApiResult<SimpleResponse>> markMessageAsRead({
    required String conversationId,
    required String messageId,
  });

  Future<ApiResult<DisputeList>> getDisputes();

  Future<ApiResult<SimpleResponse>> requestPayout(
    String paymentMethodId,
    double amount,
  );

  Future<ApiResult<SimpleResponse>> deleteAccount();

  Future<ApiResult<NotificationsList>> getNotifications({
    String? page,
    int? perPage,
  });

  Future<ApiResult<SimpleResponse>> markNotificationAsRead(
    String notificationId,
  );

  Future<ApiResult<SimpleResponse>> updateCustomerBillingInfo({
    required String name,
    required String email,
    required String city,
    required String zipCode,
    required String location,
  });

  Future<ApiResult<SimpleResponse>> updateCustomerPreferences(
    Preferences prefs,
  );

  Future<ApiResult<SimpleResponse>> updateCustomerNotificationSettings(
    Notifications prefs,
  );
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
    required String photoPath,
  }) =>
      _remoteSource.updateIdentityInfo(
        documentNumber: documentNumber,
        filePath: filePath,
        photoPath: photoPath,
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
    String? gender,
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
        gender: gender,
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
  Future<ApiResult<AvailabilitySchedule>> getAvailability() =>
      _remoteSource.getAvailability();

  @override
  Future<ApiResult<SimpleResponse>> updateAvailability({
    bool? isAvailable,
    List<ScheduleParams>? schedules,
  }) =>
      _remoteSource.updateAvailability(
        isAvailable: isAvailable,
        schedules: schedules,
      );

  @override
  Future<ApiResult<StylistEarnings>> getEarnings() =>
      _remoteSource.getEarnings();

  @override
  Future<ApiResult<SimpleResponse>> updateUser({
    bool? useLocation,
    String? address,
    String? fcmToken,
  }) =>
      _remoteSource.updateUser(
        useLocation: useLocation,
        address: address,
        fcmToken: fcmToken,
      );

  @override
  Future<ApiResult<CustomerProfileDetails>> getCustomerProfile() =>
      _remoteSource.getCustomerProfile();

  @override
  Future<ApiResult<CustomerStats>> getCustomerStats() =>
      _remoteSource.getCustomerStats();

  @override
  Future<ApiResult<CustomerWallet>> getWallet() => _remoteSource.getWallet();

  @override
  Future<ApiResult<CustomerWalletTransactionList>> getWalletTransactions({
    String? page,
    int? perPage = 10,
  }) =>
      _remoteSource.getWalletTransactions(
        page: page,
        perPage: perPage,
      );

  @override
  Future<ApiResult<PayfastPaymentData>> initialisePayfastDeposit({
    required String type,
    required String amount,
    String? email,
    String? firstName,
    String? lastName,
    String? portfolioId,
  }) {
    return _remoteSource.initialisePayfastDeposit(
      type: type,
      amount: amount,
      email: email,
      firstName: firstName,
      lastName: lastName,
      portfolioId: portfolioId,
    );
  }

  @override
  Future<ApiResult<List<ChatConversation>>> getChatConversations() =>
      _remoteSource.getChatConversations();

  @override
  Future<ApiResult<ChatMessageList>> getChatMessages(String conversationId) =>
      _remoteSource.getChatMessages(conversationId);

  @override
  Future<ApiResult<SimpleResponse>> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) =>
      _remoteSource.markMessageAsRead(
        conversationId: conversationId,
        messageId: messageId,
      );

  @override
  Future<ApiResult<SimpleResponse>> sendMessage({
    required String conversationId,
    required String text,
  }) =>
      _remoteSource.sendMessage(conversationId: conversationId, text: text);

  @override
  Future<ApiResult<ChatConversation>> startConversation({
    required String recipientId,
  }) =>
      _remoteSource.startConversation(recipientId: recipientId);

  @override
  Future<ApiResult<DisputeList>> getDisputes() => _remoteSource.getDisputes();

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
    return _remoteSource.updateCustomerProfile(
      avatar: avatar,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      country: country,
      yearsOfExperience: yearsOfExperience,
      bio: bio,
      gender: gender,
    );
  }

  @override
  Future<ApiResult<SimpleResponse>> requestPayout(
    String paymentMethodId,
    double amount,
  ) =>
      _remoteSource.requestPayout(paymentMethodId, amount);

  @override
  Future<ApiResult<SimpleResponse>> deleteAccount() =>
      _remoteSource.deleteAccount();

  @override
  Future<ApiResult<NotificationsList>> getNotifications({
    String? page,
    int? perPage,
  }) =>
      _remoteSource.getNotifications(
        page: page,
        perPage: perPage,
      );

  @override
  Future<ApiResult<SimpleResponse>> markNotificationAsRead(
    String notificationId,
  ) =>
      _remoteSource.markNotificationAsRead(notificationId);

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerBillingInfo({
    required String name,
    required String email,
    required String city,
    required String zipCode,
    required String location,
  }) =>
      _remoteSource.updateCustomerBillingInfo(
        name: name,
        email: email,
        city: city,
        zipCode: zipCode,
        location: location,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerNotificationSettings(
    Notifications prefs,
  ) =>
      _remoteSource.updateCustomerNotificationSettings(prefs);

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerPreferences(
    Preferences prefs,
  ) =>
      _remoteSource.updateCustomerPreferences(prefs);
}
