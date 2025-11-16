// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i44;
import 'package:flutter/material.dart' as _i45;
import 'package:snip_fair/core/domain/entities/chat_conversations_list/chat_conversation.dart'
    as _i46;
import 'package:snip_fair/core/domain/entities/chat_conversations_list/initiator.dart'
    as _i48;
import 'package:snip_fair/core/domain/entities/chat_conversations_list/recipient.dart'
    as _i47;
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart'
    as _i50;
import 'package:snip_fair/core/domain/entities/work_list/work_item.dart'
    as _i49;
import 'package:snip_fair/core/presentation/main_screen.dart' as _i20;
import 'package:snip_fair/features/account/change_password/views/change_password_screen.dart'
    as _i3;
import 'package:snip_fair/features/account/customer/billing_info/view/customer_billing_info_screen.dart'
    as _i7;
import 'package:snip_fair/features/account/customer/notification_settings/view/customer_notif_settings_screen.dart'
    as _i9;
import 'package:snip_fair/features/account/customer/payment_history/view/customer_payment_history_screen.dart'
    as _i10;
import 'package:snip_fair/features/account/customer/personal_details/views/customer_personal_details_screen.dart'
    as _i11;
import 'package:snip_fair/features/account/customer/preferences/view/customer_preferences_screen.dart'
    as _i12;
import 'package:snip_fair/features/account/customer/profile_management/views/customer_profile_mgt_screen.dart'
    as _i13;
import 'package:snip_fair/features/account/seller/availability/views/seller_availability_schedule_screen.dart'
    as _i27;
import 'package:snip_fair/features/account/seller/earnings/views/seller_earning_screen.dart'
    as _i30;
import 'package:snip_fair/features/account/seller/payment_methods/views/seller_payment_methods_screen.dart'
    as _i31;
import 'package:snip_fair/features/account/seller/personal_details/views/seller_personal_details_screen.dart'
    as _i32;
import 'package:snip_fair/features/account/seller/profile_management/views/seller_profile_management_screen.dart'
    as _i34;
import 'package:snip_fair/features/account/seller/profile_verification/views/seller_profile_verification_screen.dart'
    as _i35;
import 'package:snip_fair/features/account/seller/work/views/seller_add_new_work_screen.dart'
    as _i23;
import 'package:snip_fair/features/account/seller/work/views/seller_portfolio_screen.dart'
    as _i33;
import 'package:snip_fair/features/account/seller/work/views/seller_work_screen.dart'
    as _i36;
import 'package:snip_fair/features/account/views/account_main_screen.dart'
    as _i1;
import 'package:snip_fair/features/appointments/customer_appointments/views/appointements_main_screen.dart'
    as _i2;
import 'package:snip_fair/features/appointments/customer_appointments/views/customer_appointments_calendar_screen.dart'
    as _i6;
import 'package:snip_fair/features/appointments/stylist_appointments/details/views/seller_appointment_details_screen.dart'
    as _i24;
import 'package:snip_fair/features/appointments/stylist_appointments/views/seller_appointments_calendar_screen.dart'
    as _i25;
import 'package:snip_fair/features/appointments/stylist_appointments/views/seller_appointments_main_screen.dart'
    as _i26;
import 'package:snip_fair/features/appointments/update_create_appointment/views/update_create_appointment_screen.dart'
    as _i42;
import 'package:snip_fair/features/authentication/forgot_password/views/forgot_password_screen.dart'
    as _i17;
import 'package:snip_fair/features/authentication/login/views/login_screen.dart'
    as _i19;
import 'package:snip_fair/features/authentication/signup/views/signup_screen.dart'
    as _i37;
import 'package:snip_fair/features/authentication/verify_email/views/verify_email_screen.dart'
    as _i43;
import 'package:snip_fair/features/conversations/conversation/views/conversation_chat_screen.dart'
    as _i5;
import 'package:snip_fair/features/conversations/conversations_list/views/conversation_list_screen.dart'
    as _i4;
import 'package:snip_fair/features/dashboard/views/seller_dashboard_main_screen.dart'
    as _i29;
import 'package:snip_fair/features/disputes/views/disputes_screen.dart' as _i15;
import 'package:snip_fair/features/explore/views/explore_main_screen.dart'
    as _i16;
import 'package:snip_fair/features/favorites/views/customer_favorites_screen.dart'
    as _i8;
import 'package:snip_fair/features/notifications/views/notifications_screen.dart'
    as _i21;
import 'package:snip_fair/features/onboarding/views/landing_screen.dart'
    as _i18;
import 'package:snip_fair/features/onboarding/views/splash_screen.dart' as _i38;
import 'package:snip_fair/features/stylists/onboard/views/seller_business_create_screen.dart'
    as _i28;
import 'package:snip_fair/features/stylists/onboard/views/seller_business_id_verify.dart'
    as _i39;
import 'package:snip_fair/features/stylists/search/views/search_main_screen.dart'
    as _i22;
import 'package:snip_fair/features/stylists/stylist_profile/views/stylist_more_info_screen.dart'
    as _i40;
import 'package:snip_fair/features/stylists/stylist_profile/views/stylist_seller_details_screen.dart'
    as _i41;
import 'package:snip_fair/features/wallet/views/customer_wallet_screen.dart'
    as _i14;

/// generated route for
/// [_i1.AccountMainScreen]
class AccountMainRoute extends _i44.PageRouteInfo<void> {
  const AccountMainRoute({List<_i44.PageRouteInfo>? children})
      : super(AccountMainRoute.name, initialChildren: children);

  static const String name = 'AccountMainRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i1.AccountMainScreen();
    },
  );
}

/// generated route for
/// [_i2.AppointementsMainScreen]
class AppointementsMainRoute extends _i44.PageRouteInfo<void> {
  const AppointementsMainRoute({List<_i44.PageRouteInfo>? children})
      : super(AppointementsMainRoute.name, initialChildren: children);

  static const String name = 'AppointementsMainRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i2.AppointementsMainScreen();
    },
  );
}

/// generated route for
/// [_i3.ChangePasswordScreen]
class ChangePasswordRoute extends _i44.PageRouteInfo<void> {
  const ChangePasswordRoute({List<_i44.PageRouteInfo>? children})
      : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i3.ChangePasswordScreen());
    },
  );
}

/// generated route for
/// [_i4.ConversationListScreen]
class ConversationListRoute
    extends _i44.PageRouteInfo<ConversationListRouteArgs> {
  ConversationListRoute({
    _i45.Key? key,
    _i46.ChatConversation? chatConversation,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          ConversationListRoute.name,
          args: ConversationListRouteArgs(
            key: key,
            chatConversation: chatConversation,
          ),
          initialChildren: children,
        );

  static const String name = 'ConversationListRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ConversationListRouteArgs>(
        orElse: () => const ConversationListRouteArgs(),
      );
      return _i4.ConversationListScreen(
        key: args.key,
        chatConversation: args.chatConversation,
      );
    },
  );
}

class ConversationListRouteArgs {
  const ConversationListRouteArgs({this.key, this.chatConversation});

  final _i45.Key? key;

  final _i46.ChatConversation? chatConversation;

  @override
  String toString() {
    return 'ConversationListRouteArgs{key: $key, chatConversation: $chatConversation}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConversationListRouteArgs) return false;
    return key == other.key && chatConversation == other.chatConversation;
  }

  @override
  int get hashCode => key.hashCode ^ chatConversation.hashCode;
}

/// generated route for
/// [_i5.ConvesationChatScreen]
class ConvesationChatRoute
    extends _i44.PageRouteInfo<ConvesationChatRouteArgs> {
  ConvesationChatRoute({
    required String conversationId,
    required String currentUserId,
    _i47.Recipient? recipient,
    _i48.Initiator? initiator,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          ConvesationChatRoute.name,
          args: ConvesationChatRouteArgs(
            conversationId: conversationId,
            currentUserId: currentUserId,
            recipient: recipient,
            initiator: initiator,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'ConvesationChatRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ConvesationChatRouteArgs>();
      return _i5.ConvesationChatScreen(
        conversationId: args.conversationId,
        currentUserId: args.currentUserId,
        recipient: args.recipient,
        initiator: args.initiator,
        key: args.key,
      );
    },
  );
}

class ConvesationChatRouteArgs {
  const ConvesationChatRouteArgs({
    required this.conversationId,
    required this.currentUserId,
    this.recipient,
    this.initiator,
    this.key,
  });

  final String conversationId;

  final String currentUserId;

  final _i47.Recipient? recipient;

  final _i48.Initiator? initiator;

  final _i45.Key? key;

  @override
  String toString() {
    return 'ConvesationChatRouteArgs{conversationId: $conversationId, currentUserId: $currentUserId, recipient: $recipient, initiator: $initiator, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConvesationChatRouteArgs) return false;
    return conversationId == other.conversationId &&
        currentUserId == other.currentUserId &&
        recipient == other.recipient &&
        initiator == other.initiator &&
        key == other.key;
  }

  @override
  int get hashCode =>
      conversationId.hashCode ^
      currentUserId.hashCode ^
      recipient.hashCode ^
      initiator.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i6.CustomerAppointmentsCalendarScreen]
class CustomerAppointmentsCalendarRoute extends _i44.PageRouteInfo<void> {
  const CustomerAppointmentsCalendarRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerAppointmentsCalendarRoute.name,
            initialChildren: children);

  static const String name = 'CustomerAppointmentsCalendarRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i6.CustomerAppointmentsCalendarScreen();
    },
  );
}

/// generated route for
/// [_i7.CustomerBillingInfoScreen]
class CustomerBillingInfoRoute extends _i44.PageRouteInfo<void> {
  const CustomerBillingInfoRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerBillingInfoRoute.name, initialChildren: children);

  static const String name = 'CustomerBillingInfoRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i7.CustomerBillingInfoScreen());
    },
  );
}

/// generated route for
/// [_i8.CustomerFavoritesScreen]
class CustomerFavoritesRoute extends _i44.PageRouteInfo<void> {
  const CustomerFavoritesRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerFavoritesRoute.name, initialChildren: children);

  static const String name = 'CustomerFavoritesRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i8.CustomerFavoritesScreen());
    },
  );
}

/// generated route for
/// [_i9.CustomerNotifSettingsScreen]
class CustomerNotifSettingsRoute extends _i44.PageRouteInfo<void> {
  const CustomerNotifSettingsRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerNotifSettingsRoute.name, initialChildren: children);

  static const String name = 'CustomerNotifSettingsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i9.CustomerNotifSettingsScreen());
    },
  );
}

/// generated route for
/// [_i10.CustomerPaymentHistoryScreen]
class CustomerPaymentHistoryRoute extends _i44.PageRouteInfo<void> {
  const CustomerPaymentHistoryRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerPaymentHistoryRoute.name, initialChildren: children);

  static const String name = 'CustomerPaymentHistoryRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i10.CustomerPaymentHistoryScreen();
    },
  );
}

/// generated route for
/// [_i11.CustomerPersonalDetailsScreen]
class CustomerPersonalDetailsRoute extends _i44.PageRouteInfo<void> {
  const CustomerPersonalDetailsRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerPersonalDetailsRoute.name, initialChildren: children);

  static const String name = 'CustomerPersonalDetailsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(
        child: const _i11.CustomerPersonalDetailsScreen(),
      );
    },
  );
}

/// generated route for
/// [_i12.CustomerPreferencesScreen]
class CustomerPreferencesRoute extends _i44.PageRouteInfo<void> {
  const CustomerPreferencesRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerPreferencesRoute.name, initialChildren: children);

  static const String name = 'CustomerPreferencesRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i12.CustomerPreferencesScreen());
    },
  );
}

/// generated route for
/// [_i13.CustomerProfileMgtScreen]
class CustomerProfileMgtRoute extends _i44.PageRouteInfo<void> {
  const CustomerProfileMgtRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerProfileMgtRoute.name, initialChildren: children);

  static const String name = 'CustomerProfileMgtRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i13.CustomerProfileMgtScreen();
    },
  );
}

/// generated route for
/// [_i14.CustomerWalletScreen]
class CustomerWalletRoute extends _i44.PageRouteInfo<void> {
  const CustomerWalletRoute({List<_i44.PageRouteInfo>? children})
      : super(CustomerWalletRoute.name, initialChildren: children);

  static const String name = 'CustomerWalletRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i14.CustomerWalletScreen();
    },
  );
}

/// generated route for
/// [_i15.DisputesScreen]
class DisputesRoute extends _i44.PageRouteInfo<void> {
  const DisputesRoute({List<_i44.PageRouteInfo>? children})
      : super(DisputesRoute.name, initialChildren: children);

  static const String name = 'DisputesRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i15.DisputesScreen());
    },
  );
}

/// generated route for
/// [_i16.ExploreMainScreen]
class ExploreMainRoute extends _i44.PageRouteInfo<void> {
  const ExploreMainRoute({List<_i44.PageRouteInfo>? children})
      : super(ExploreMainRoute.name, initialChildren: children);

  static const String name = 'ExploreMainRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i16.ExploreMainScreen());
    },
  );
}

/// generated route for
/// [_i17.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i44.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i44.PageRouteInfo>? children})
      : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i17.ForgotPasswordScreen());
    },
  );
}

/// generated route for
/// [_i18.LandingScreen]
class LandingRoute extends _i44.PageRouteInfo<void> {
  const LandingRoute({List<_i44.PageRouteInfo>? children})
      : super(LandingRoute.name, initialChildren: children);

  static const String name = 'LandingRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i18.LandingScreen();
    },
  );
}

/// generated route for
/// [_i19.LoginScreen]
class LoginRoute extends _i44.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i45.Key? key,
    bool isStylist = false,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          LoginRoute.name,
          args: LoginRouteArgs(key: key, isStylist: isStylist),
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () => const LoginRouteArgs(),
      );
      return _i44.WrappedRoute(
        child: _i19.LoginScreen(key: args.key, isStylist: args.isStylist),
      );
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.isStylist = false});

  final _i45.Key? key;

  final bool isStylist;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, isStylist: $isStylist}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key && isStylist == other.isStylist;
  }

  @override
  int get hashCode => key.hashCode ^ isStylist.hashCode;
}

/// generated route for
/// [_i20.MainScreen]
class MainRoute extends _i44.PageRouteInfo<void> {
  const MainRoute({List<_i44.PageRouteInfo>? children})
      : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i20.MainScreen();
    },
  );
}

/// generated route for
/// [_i21.NotificationsScreen]
class NotificationsRoute extends _i44.PageRouteInfo<void> {
  const NotificationsRoute({List<_i44.PageRouteInfo>? children})
      : super(NotificationsRoute.name, initialChildren: children);

  static const String name = 'NotificationsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i21.NotificationsScreen();
    },
  );
}

/// generated route for
/// [_i22.SearchMainScreen]
class SearchMainRoute extends _i44.PageRouteInfo<void> {
  const SearchMainRoute({List<_i44.PageRouteInfo>? children})
      : super(SearchMainRoute.name, initialChildren: children);

  static const String name = 'SearchMainRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i22.SearchMainScreen());
    },
  );
}

/// generated route for
/// [_i23.SellerAddNewWorkScreen]
class SellerAddNewWorkRoute extends _i44.PageRouteInfo<void> {
  const SellerAddNewWorkRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerAddNewWorkRoute.name, initialChildren: children);

  static const String name = 'SellerAddNewWorkRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i23.SellerAddNewWorkScreen();
    },
  );
}

/// generated route for
/// [_i24.SellerAppointmentDetailsScreen]
class SellerAppointmentDetailsRoute
    extends _i44.PageRouteInfo<SellerAppointmentDetailsRouteArgs> {
  SellerAppointmentDetailsRoute({
    required String? appointmentId,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          SellerAppointmentDetailsRoute.name,
          args: SellerAppointmentDetailsRouteArgs(
            appointmentId: appointmentId,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'SellerAppointmentDetailsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SellerAppointmentDetailsRouteArgs>();
      return _i44.WrappedRoute(
        child: _i24.SellerAppointmentDetailsScreen(
          appointmentId: args.appointmentId,
          key: args.key,
        ),
      );
    },
  );
}

class SellerAppointmentDetailsRouteArgs {
  const SellerAppointmentDetailsRouteArgs({
    required this.appointmentId,
    this.key,
  });

  final String? appointmentId;

  final _i45.Key? key;

  @override
  String toString() {
    return 'SellerAppointmentDetailsRouteArgs{appointmentId: $appointmentId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SellerAppointmentDetailsRouteArgs) return false;
    return appointmentId == other.appointmentId && key == other.key;
  }

  @override
  int get hashCode => appointmentId.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i25.SellerAppointmentsCalendarScreen]
class SellerAppointmentsCalendarRoute extends _i44.PageRouteInfo<void> {
  const SellerAppointmentsCalendarRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerAppointmentsCalendarRoute.name, initialChildren: children);

  static const String name = 'SellerAppointmentsCalendarRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i25.SellerAppointmentsCalendarScreen();
    },
  );
}

/// generated route for
/// [_i26.SellerAppointmentsMainScreen]
class SellerAppointmentsMainRoute extends _i44.PageRouteInfo<void> {
  const SellerAppointmentsMainRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerAppointmentsMainRoute.name, initialChildren: children);

  static const String name = 'SellerAppointmentsMainRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i26.SellerAppointmentsMainScreen();
    },
  );
}

/// generated route for
/// [_i27.SellerAvailabilityScheduleScreen]
class SellerAvailabilityScheduleRoute
    extends _i44.PageRouteInfo<SellerAvailabilityScheduleRouteArgs> {
  SellerAvailabilityScheduleRoute({
    _i45.Key? key,
    bool goToLocationSettings = false,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          SellerAvailabilityScheduleRoute.name,
          args: SellerAvailabilityScheduleRouteArgs(
            key: key,
            goToLocationSettings: goToLocationSettings,
          ),
          initialChildren: children,
        );

  static const String name = 'SellerAvailabilityScheduleRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SellerAvailabilityScheduleRouteArgs>(
        orElse: () => const SellerAvailabilityScheduleRouteArgs(),
      );
      return _i44.WrappedRoute(
        child: _i27.SellerAvailabilityScheduleScreen(
          key: args.key,
          goToLocationSettings: args.goToLocationSettings,
        ),
      );
    },
  );
}

class SellerAvailabilityScheduleRouteArgs {
  const SellerAvailabilityScheduleRouteArgs({
    this.key,
    this.goToLocationSettings = false,
  });

  final _i45.Key? key;

  final bool goToLocationSettings;

  @override
  String toString() {
    return 'SellerAvailabilityScheduleRouteArgs{key: $key, goToLocationSettings: $goToLocationSettings}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SellerAvailabilityScheduleRouteArgs) return false;
    return key == other.key &&
        goToLocationSettings == other.goToLocationSettings;
  }

  @override
  int get hashCode => key.hashCode ^ goToLocationSettings.hashCode;
}

/// generated route for
/// [_i28.SellerBusinessCreateScreen]
class SellerBusinessCreateRoute
    extends _i44.PageRouteInfo<SellerBusinessCreateRouteArgs> {
  SellerBusinessCreateRoute({
    _i45.Key? key,
    bool fromSignUp = false,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          SellerBusinessCreateRoute.name,
          args: SellerBusinessCreateRouteArgs(key: key, fromSignUp: fromSignUp),
          initialChildren: children,
        );

  static const String name = 'SellerBusinessCreateRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SellerBusinessCreateRouteArgs>(
        orElse: () => const SellerBusinessCreateRouteArgs(),
      );
      return _i44.WrappedRoute(
        child: _i28.SellerBusinessCreateScreen(
          key: args.key,
          fromSignUp: args.fromSignUp,
        ),
      );
    },
  );
}

class SellerBusinessCreateRouteArgs {
  const SellerBusinessCreateRouteArgs({this.key, this.fromSignUp = false});

  final _i45.Key? key;

  final bool fromSignUp;

  @override
  String toString() {
    return 'SellerBusinessCreateRouteArgs{key: $key, fromSignUp: $fromSignUp}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SellerBusinessCreateRouteArgs) return false;
    return key == other.key && fromSignUp == other.fromSignUp;
  }

  @override
  int get hashCode => key.hashCode ^ fromSignUp.hashCode;
}

/// generated route for
/// [_i29.SellerDashboardMainScreen]
class SellerDashboardMainRoute extends _i44.PageRouteInfo<void> {
  const SellerDashboardMainRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerDashboardMainRoute.name, initialChildren: children);

  static const String name = 'SellerDashboardMainRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i29.SellerDashboardMainScreen();
    },
  );
}

/// generated route for
/// [_i30.SellerEarningScreen]
class SellerEarningRoute extends _i44.PageRouteInfo<void> {
  const SellerEarningRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerEarningRoute.name, initialChildren: children);

  static const String name = 'SellerEarningRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i30.SellerEarningScreen());
    },
  );
}

/// generated route for
/// [_i31.SellerPaymentMethodsScreen]
class SellerPaymentMethodsRoute extends _i44.PageRouteInfo<void> {
  const SellerPaymentMethodsRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerPaymentMethodsRoute.name, initialChildren: children);

  static const String name = 'SellerPaymentMethodsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i31.SellerPaymentMethodsScreen());
    },
  );
}

/// generated route for
/// [_i32.SellerPersonalDetailsScreen]
class SellerPersonalDetailsRoute extends _i44.PageRouteInfo<void> {
  const SellerPersonalDetailsRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerPersonalDetailsRoute.name, initialChildren: children);

  static const String name = 'SellerPersonalDetailsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i32.SellerPersonalDetailsScreen());
    },
  );
}

/// generated route for
/// [_i33.SellerPortfolioScreen]
class SellerPortfolioRoute extends _i44.PageRouteInfo<void> {
  const SellerPortfolioRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerPortfolioRoute.name, initialChildren: children);

  static const String name = 'SellerPortfolioRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(child: const _i33.SellerPortfolioScreen());
    },
  );
}

/// generated route for
/// [_i34.SellerProfileManagementScreen]
class SellerProfileManagementRoute extends _i44.PageRouteInfo<void> {
  const SellerProfileManagementRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerProfileManagementRoute.name, initialChildren: children);

  static const String name = 'SellerProfileManagementRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i34.SellerProfileManagementScreen();
    },
  );
}

/// generated route for
/// [_i35.SellerProfileVerificationScreen]
class SellerProfileVerificationRoute extends _i44.PageRouteInfo<void> {
  const SellerProfileVerificationRoute({List<_i44.PageRouteInfo>? children})
      : super(SellerProfileVerificationRoute.name, initialChildren: children);

  static const String name = 'SellerProfileVerificationRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return _i44.WrappedRoute(
        child: const _i35.SellerProfileVerificationScreen(),
      );
    },
  );
}

/// generated route for
/// [_i36.SellerWorkScreen]
class SellerWorkRoute extends _i44.PageRouteInfo<SellerWorkRouteArgs> {
  SellerWorkRoute({
    _i45.Key? key,
    _i49.WorkItem? workItem,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          SellerWorkRoute.name,
          args: SellerWorkRouteArgs(key: key, workItem: workItem),
          initialChildren: children,
        );

  static const String name = 'SellerWorkRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SellerWorkRouteArgs>(
        orElse: () => const SellerWorkRouteArgs(),
      );
      return _i44.WrappedRoute(
        child: _i36.SellerWorkScreen(key: args.key, workItem: args.workItem),
      );
    },
  );
}

class SellerWorkRouteArgs {
  const SellerWorkRouteArgs({this.key, this.workItem});

  final _i45.Key? key;

  final _i49.WorkItem? workItem;

  @override
  String toString() {
    return 'SellerWorkRouteArgs{key: $key, workItem: $workItem}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SellerWorkRouteArgs) return false;
    return key == other.key && workItem == other.workItem;
  }

  @override
  int get hashCode => key.hashCode ^ workItem.hashCode;
}

/// generated route for
/// [_i37.SignupScreen]
class SignupRoute extends _i44.PageRouteInfo<SignupRouteArgs> {
  SignupRoute({
    bool asStylist = false,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          SignupRoute.name,
          args: SignupRouteArgs(asStylist: asStylist, key: key),
          initialChildren: children,
        );

  static const String name = 'SignupRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SignupRouteArgs>(
        orElse: () => const SignupRouteArgs(),
      );
      return _i44.WrappedRoute(
        child: _i37.SignupScreen(asStylist: args.asStylist, key: args.key),
      );
    },
  );
}

class SignupRouteArgs {
  const SignupRouteArgs({this.asStylist = false, this.key});

  final bool asStylist;

  final _i45.Key? key;

  @override
  String toString() {
    return 'SignupRouteArgs{asStylist: $asStylist, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SignupRouteArgs) return false;
    return asStylist == other.asStylist && key == other.key;
  }

  @override
  int get hashCode => asStylist.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i38.SplashScreen]
class SplashRoute extends _i44.PageRouteInfo<void> {
  const SplashRoute({List<_i44.PageRouteInfo>? children})
      : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i38.SplashScreen();
    },
  );
}

/// generated route for
/// [_i39.StylistBusinessIdVerifyScreen]
class StylistBusinessIdVerifyRoute
    extends _i44.PageRouteInfo<StylistBusinessIdVerifyRouteArgs> {
  StylistBusinessIdVerifyRoute({
    _i45.Key? key,
    bool fromSignUp = false,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          StylistBusinessIdVerifyRoute.name,
          args: StylistBusinessIdVerifyRouteArgs(
            key: key,
            fromSignUp: fromSignUp,
          ),
          initialChildren: children,
        );

  static const String name = 'StylistBusinessIdVerifyRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StylistBusinessIdVerifyRouteArgs>(
        orElse: () => const StylistBusinessIdVerifyRouteArgs(),
      );
      return _i44.WrappedRoute(
        child: _i39.StylistBusinessIdVerifyScreen(
          key: args.key,
          fromSignUp: args.fromSignUp,
        ),
      );
    },
  );
}

class StylistBusinessIdVerifyRouteArgs {
  const StylistBusinessIdVerifyRouteArgs({this.key, this.fromSignUp = false});

  final _i45.Key? key;

  final bool fromSignUp;

  @override
  String toString() {
    return 'StylistBusinessIdVerifyRouteArgs{key: $key, fromSignUp: $fromSignUp}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StylistBusinessIdVerifyRouteArgs) return false;
    return key == other.key && fromSignUp == other.fromSignUp;
  }

  @override
  int get hashCode => key.hashCode ^ fromSignUp.hashCode;
}

/// generated route for
/// [_i40.StylistMoreInfoScreen]
class StylistMoreInfoRoute extends _i44.PageRouteInfo<void> {
  const StylistMoreInfoRoute({List<_i44.PageRouteInfo>? children})
      : super(StylistMoreInfoRoute.name, initialChildren: children);

  static const String name = 'StylistMoreInfoRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i40.StylistMoreInfoScreen();
    },
  );
}

/// generated route for
/// [_i41.StylistSellerDetailsScreen]
class StylistSellerDetailsRoute
    extends _i44.PageRouteInfo<StylistSellerDetailsRouteArgs> {
  StylistSellerDetailsRoute({
    _i45.Key? key,
    _i50.SellerDetails? seller,
    String? id,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          StylistSellerDetailsRoute.name,
          args: StylistSellerDetailsRouteArgs(key: key, seller: seller, id: id),
          initialChildren: children,
        );

  static const String name = 'StylistSellerDetailsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StylistSellerDetailsRouteArgs>(
        orElse: () => const StylistSellerDetailsRouteArgs(),
      );
      return _i44.WrappedRoute(
        child: _i41.StylistSellerDetailsScreen(
          key: args.key,
          seller: args.seller,
          id: args.id,
        ),
      );
    },
  );
}

class StylistSellerDetailsRouteArgs {
  const StylistSellerDetailsRouteArgs({this.key, this.seller, this.id});

  final _i45.Key? key;

  final _i50.SellerDetails? seller;

  final String? id;

  @override
  String toString() {
    return 'StylistSellerDetailsRouteArgs{key: $key, seller: $seller, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StylistSellerDetailsRouteArgs) return false;
    return key == other.key && seller == other.seller && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ seller.hashCode ^ id.hashCode;
}

/// generated route for
/// [_i42.UpdateCreateAppointmentScreen]
class UpdateCreateAppointmentRoute
    extends _i44.PageRouteInfo<UpdateCreateAppointmentRouteArgs> {
  UpdateCreateAppointmentRoute({
    _i45.Key? key,
    String? portfolioId,
    String? appointmentId,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          UpdateCreateAppointmentRoute.name,
          args: UpdateCreateAppointmentRouteArgs(
            key: key,
            portfolioId: portfolioId,
            appointmentId: appointmentId,
          ),
          initialChildren: children,
        );

  static const String name = 'UpdateCreateAppointmentRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UpdateCreateAppointmentRouteArgs>(
        orElse: () => const UpdateCreateAppointmentRouteArgs(),
      );
      return _i44.WrappedRoute(
        child: _i42.UpdateCreateAppointmentScreen(
          key: args.key,
          portfolioId: args.portfolioId,
          appointmentId: args.appointmentId,
        ),
      );
    },
  );
}

class UpdateCreateAppointmentRouteArgs {
  const UpdateCreateAppointmentRouteArgs({
    this.key,
    this.portfolioId,
    this.appointmentId,
  });

  final _i45.Key? key;

  final String? portfolioId;

  final String? appointmentId;

  @override
  String toString() {
    return 'UpdateCreateAppointmentRouteArgs{key: $key, portfolioId: $portfolioId, appointmentId: $appointmentId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UpdateCreateAppointmentRouteArgs) return false;
    return key == other.key &&
        portfolioId == other.portfolioId &&
        appointmentId == other.appointmentId;
  }

  @override
  int get hashCode =>
      key.hashCode ^ portfolioId.hashCode ^ appointmentId.hashCode;
}

/// generated route for
/// [_i43.VerifyEmailScreen]
class VerifyEmailRoute extends _i44.PageRouteInfo<VerifyEmailRouteArgs> {
  VerifyEmailRoute({
    required String email,
    bool asStylist = false,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
          VerifyEmailRoute.name,
          args: VerifyEmailRouteArgs(
            email: email,
            asStylist: asStylist,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'VerifyEmailRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VerifyEmailRouteArgs>();
      return _i44.WrappedRoute(
        child: _i43.VerifyEmailScreen(
          email: args.email,
          asStylist: args.asStylist,
          key: args.key,
        ),
      );
    },
  );
}

class VerifyEmailRouteArgs {
  const VerifyEmailRouteArgs({
    required this.email,
    this.asStylist = false,
    this.key,
  });

  final String email;

  final bool asStylist;

  final _i45.Key? key;

  @override
  String toString() {
    return 'VerifyEmailRouteArgs{email: $email, asStylist: $asStylist, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VerifyEmailRouteArgs) return false;
    return email == other.email &&
        asStylist == other.asStylist &&
        key == other.key;
  }

  @override
  int get hashCode => email.hashCode ^ asStylist.hashCode ^ key.hashCode;
}
