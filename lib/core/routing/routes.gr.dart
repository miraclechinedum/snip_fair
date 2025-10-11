// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i29;
import 'package:flutter/material.dart' as _i30;
import 'package:snip_fair/core/domain/entities/work_list/work_item.dart'
    as _i31;
import 'package:snip_fair/core/presentation/main_screen.dart' as _i9;
import 'package:snip_fair/features/account/availability/views/seller_availability_schedule_screen.dart'
    as _i12;
import 'package:snip_fair/features/account/change_password/views/change_password_screen.dart'
    as _i4;
import 'package:snip_fair/features/account/earnings/views/seller_earning_screen.dart'
    as _i15;
import 'package:snip_fair/features/account/payment_methods/views/seller_payment_methods_screen.dart'
    as _i16;
import 'package:snip_fair/features/account/personal_details/views/personal_details_screen.dart'
    as _i10;
import 'package:snip_fair/features/account/profile_management/views/seller_profile_management_screen.dart'
    as _i18;
import 'package:snip_fair/features/account/profile_verification/views/seller_profile_verification_screen.dart'
    as _i19;
import 'package:snip_fair/features/account/views/account_main_screen.dart'
    as _i1;
import 'package:snip_fair/features/account/work/views/seller_add_new_work_screen.dart'
    as _i11;
import 'package:snip_fair/features/account/work/views/seller_portfolio_screen.dart'
    as _i17;
import 'package:snip_fair/features/account/work/views/seller_work_screen.dart'
    as _i20;
import 'package:snip_fair/features/appointments/stylist_appointments/views/stylist_appointments_main_screen.dart'
    as _i23;
import 'package:snip_fair/features/appointments/views/appointements_main_screen.dart'
    as _i2;
import 'package:snip_fair/features/authentication/forgot_password/views/forgot_password_screen.dart'
    as _i6;
import 'package:snip_fair/features/authentication/login/views/login_screen.dart'
    as _i8;
import 'package:snip_fair/features/authentication/signup/views/signup_screen.dart'
    as _i21;
import 'package:snip_fair/features/authentication/verify_email/views/verify_email_screen.dart'
    as _i28;
import 'package:snip_fair/features/booking/views/book_stylist_screen.dart'
    as _i3;
import 'package:snip_fair/features/dashboard/views/seller_dashboard_main_screen.dart'
    as _i14;
import 'package:snip_fair/features/explore/views/explore_main_screen.dart'
    as _i5;
import 'package:snip_fair/features/onboarding/views/landing_screen.dart' as _i7;
import 'package:snip_fair/features/onboarding/views/splash_screen.dart' as _i22;
import 'package:snip_fair/features/stylists/onboard/views/seller_business_create_screen.dart'
    as _i13;
import 'package:snip_fair/features/stylists/onboard/views/seller_business_id_verify.dart'
    as _i24;
import 'package:snip_fair/features/stylists/stylist_profile/views/stylist_more_info_screen.dart'
    as _i25;
import 'package:snip_fair/features/stylists/stylist_profile/views/stylist_profile_screen.dart'
    as _i26;
import 'package:snip_fair/features/stylists/views/stylists_main_screen.dart'
    as _i27;

/// generated route for
/// [_i1.AccountMainScreen]
class AccountMainRoute extends _i29.PageRouteInfo<void> {
  const AccountMainRoute({List<_i29.PageRouteInfo>? children})
      : super(AccountMainRoute.name, initialChildren: children);

  static const String name = 'AccountMainRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i1.AccountMainScreen();
    },
  );
}

/// generated route for
/// [_i2.AppointementsMainScreen]
class AppointementsMainRoute extends _i29.PageRouteInfo<void> {
  const AppointementsMainRoute({List<_i29.PageRouteInfo>? children})
      : super(AppointementsMainRoute.name, initialChildren: children);

  static const String name = 'AppointementsMainRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i2.AppointementsMainScreen();
    },
  );
}

/// generated route for
/// [_i3.BookStylistScreen]
class BookStylistRoute extends _i29.PageRouteInfo<void> {
  const BookStylistRoute({List<_i29.PageRouteInfo>? children})
      : super(BookStylistRoute.name, initialChildren: children);

  static const String name = 'BookStylistRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i3.BookStylistScreen();
    },
  );
}

/// generated route for
/// [_i4.ChangePasswordScreen]
class ChangePasswordRoute extends _i29.PageRouteInfo<void> {
  const ChangePasswordRoute({List<_i29.PageRouteInfo>? children})
      : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return _i29.WrappedRoute(child: const _i4.ChangePasswordScreen());
    },
  );
}

/// generated route for
/// [_i5.ExploreMainScreen]
class ExploreMainRoute extends _i29.PageRouteInfo<void> {
  const ExploreMainRoute({List<_i29.PageRouteInfo>? children})
      : super(ExploreMainRoute.name, initialChildren: children);

  static const String name = 'ExploreMainRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i5.ExploreMainScreen();
    },
  );
}

/// generated route for
/// [_i6.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i29.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i29.PageRouteInfo>? children})
      : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return _i29.WrappedRoute(child: const _i6.ForgotPasswordScreen());
    },
  );
}

/// generated route for
/// [_i7.LandingScreen]
class LandingRoute extends _i29.PageRouteInfo<void> {
  const LandingRoute({List<_i29.PageRouteInfo>? children})
      : super(LandingRoute.name, initialChildren: children);

  static const String name = 'LandingRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i7.LandingScreen();
    },
  );
}

/// generated route for
/// [_i8.LoginScreen]
class LoginRoute extends _i29.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i30.Key? key,
    bool isStylist = false,
    List<_i29.PageRouteInfo>? children,
  }) : super(
          LoginRoute.name,
          args: LoginRouteArgs(key: key, isStylist: isStylist),
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () => const LoginRouteArgs(),
      );
      return _i29.WrappedRoute(
        child: _i8.LoginScreen(key: args.key, isStylist: args.isStylist),
      );
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.isStylist = false});

  final _i30.Key? key;

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
/// [_i9.MainScreen]
class MainRoute extends _i29.PageRouteInfo<void> {
  const MainRoute({List<_i29.PageRouteInfo>? children})
      : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i9.MainScreen();
    },
  );
}

/// generated route for
/// [_i10.PersonalDetailsScreen]
class PersonalDetailsRoute extends _i29.PageRouteInfo<void> {
  const PersonalDetailsRoute({List<_i29.PageRouteInfo>? children})
      : super(PersonalDetailsRoute.name, initialChildren: children);

  static const String name = 'PersonalDetailsRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return _i29.WrappedRoute(child: const _i10.PersonalDetailsScreen());
    },
  );
}

/// generated route for
/// [_i11.SellerAddNewWorkScreen]
class SellerAddNewWorkRoute extends _i29.PageRouteInfo<void> {
  const SellerAddNewWorkRoute({List<_i29.PageRouteInfo>? children})
      : super(SellerAddNewWorkRoute.name, initialChildren: children);

  static const String name = 'SellerAddNewWorkRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i11.SellerAddNewWorkScreen();
    },
  );
}

/// generated route for
/// [_i12.SellerAvailabilityScheduleScreen]
class SellerAvailabilityScheduleRoute extends _i29.PageRouteInfo<void> {
  const SellerAvailabilityScheduleRoute({List<_i29.PageRouteInfo>? children})
      : super(SellerAvailabilityScheduleRoute.name, initialChildren: children);

  static const String name = 'SellerAvailabilityScheduleRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return _i29.WrappedRoute(
        child: const _i12.SellerAvailabilityScheduleScreen(),
      );
    },
  );
}

/// generated route for
/// [_i13.SellerBusinessCreateScreen]
class SellerBusinessCreateRoute
    extends _i29.PageRouteInfo<SellerBusinessCreateRouteArgs> {
  SellerBusinessCreateRoute({
    _i30.Key? key,
    bool fromSignUp = false,
    List<_i29.PageRouteInfo>? children,
  }) : super(
          SellerBusinessCreateRoute.name,
          args: SellerBusinessCreateRouteArgs(key: key, fromSignUp: fromSignUp),
          initialChildren: children,
        );

  static const String name = 'SellerBusinessCreateRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SellerBusinessCreateRouteArgs>(
        orElse: () => const SellerBusinessCreateRouteArgs(),
      );
      return _i29.WrappedRoute(
        child: _i13.SellerBusinessCreateScreen(
          key: args.key,
          fromSignUp: args.fromSignUp,
        ),
      );
    },
  );
}

class SellerBusinessCreateRouteArgs {
  const SellerBusinessCreateRouteArgs({this.key, this.fromSignUp = false});

  final _i30.Key? key;

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
/// [_i14.SellerDashboardMainScreen]
class SellerDashboardMainRoute extends _i29.PageRouteInfo<void> {
  const SellerDashboardMainRoute({List<_i29.PageRouteInfo>? children})
      : super(SellerDashboardMainRoute.name, initialChildren: children);

  static const String name = 'SellerDashboardMainRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i14.SellerDashboardMainScreen();
    },
  );
}

/// generated route for
/// [_i15.SellerEarningScreen]
class SellerEarningRoute extends _i29.PageRouteInfo<void> {
  const SellerEarningRoute({List<_i29.PageRouteInfo>? children})
      : super(SellerEarningRoute.name, initialChildren: children);

  static const String name = 'SellerEarningRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return _i29.WrappedRoute(child: const _i15.SellerEarningScreen());
    },
  );
}

/// generated route for
/// [_i16.SellerPaymentMethodsScreen]
class SellerPaymentMethodsRoute extends _i29.PageRouteInfo<void> {
  const SellerPaymentMethodsRoute({List<_i29.PageRouteInfo>? children})
      : super(SellerPaymentMethodsRoute.name, initialChildren: children);

  static const String name = 'SellerPaymentMethodsRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return _i29.WrappedRoute(child: const _i16.SellerPaymentMethodsScreen());
    },
  );
}

/// generated route for
/// [_i17.SellerPortfolioScreen]
class SellerPortfolioRoute extends _i29.PageRouteInfo<void> {
  const SellerPortfolioRoute({List<_i29.PageRouteInfo>? children})
      : super(SellerPortfolioRoute.name, initialChildren: children);

  static const String name = 'SellerPortfolioRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return _i29.WrappedRoute(child: const _i17.SellerPortfolioScreen());
    },
  );
}

/// generated route for
/// [_i18.SellerProfileManagementScreen]
class SellerProfileManagementRoute extends _i29.PageRouteInfo<void> {
  const SellerProfileManagementRoute({List<_i29.PageRouteInfo>? children})
      : super(SellerProfileManagementRoute.name, initialChildren: children);

  static const String name = 'SellerProfileManagementRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i18.SellerProfileManagementScreen();
    },
  );
}

/// generated route for
/// [_i19.SellerProfileVerificationScreen]
class SellerProfileVerificationRoute extends _i29.PageRouteInfo<void> {
  const SellerProfileVerificationRoute({List<_i29.PageRouteInfo>? children})
      : super(SellerProfileVerificationRoute.name, initialChildren: children);

  static const String name = 'SellerProfileVerificationRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return _i29.WrappedRoute(
        child: const _i19.SellerProfileVerificationScreen(),
      );
    },
  );
}

/// generated route for
/// [_i20.SellerWorkScreen]
class SellerWorkRoute extends _i29.PageRouteInfo<SellerWorkRouteArgs> {
  SellerWorkRoute({
    _i30.Key? key,
    _i31.WorkItem? workItem,
    List<_i29.PageRouteInfo>? children,
  }) : super(
          SellerWorkRoute.name,
          args: SellerWorkRouteArgs(key: key, workItem: workItem),
          initialChildren: children,
        );

  static const String name = 'SellerWorkRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SellerWorkRouteArgs>(
        orElse: () => const SellerWorkRouteArgs(),
      );
      return _i29.WrappedRoute(
        child: _i20.SellerWorkScreen(key: args.key, workItem: args.workItem),
      );
    },
  );
}

class SellerWorkRouteArgs {
  const SellerWorkRouteArgs({this.key, this.workItem});

  final _i30.Key? key;

  final _i31.WorkItem? workItem;

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
/// [_i21.SignupScreen]
class SignupRoute extends _i29.PageRouteInfo<SignupRouteArgs> {
  SignupRoute({
    bool asStylist = false,
    _i30.Key? key,
    List<_i29.PageRouteInfo>? children,
  }) : super(
          SignupRoute.name,
          args: SignupRouteArgs(asStylist: asStylist, key: key),
          initialChildren: children,
        );

  static const String name = 'SignupRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SignupRouteArgs>(
        orElse: () => const SignupRouteArgs(),
      );
      return _i29.WrappedRoute(
        child: _i21.SignupScreen(asStylist: args.asStylist, key: args.key),
      );
    },
  );
}

class SignupRouteArgs {
  const SignupRouteArgs({this.asStylist = false, this.key});

  final bool asStylist;

  final _i30.Key? key;

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
/// [_i22.SplashScreen]
class SplashRoute extends _i29.PageRouteInfo<void> {
  const SplashRoute({List<_i29.PageRouteInfo>? children})
      : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i22.SplashScreen();
    },
  );
}

/// generated route for
/// [_i23.StylistAppointmentsMainScreen]
class StylistAppointmentsMainRoute extends _i29.PageRouteInfo<void> {
  const StylistAppointmentsMainRoute({List<_i29.PageRouteInfo>? children})
      : super(StylistAppointmentsMainRoute.name, initialChildren: children);

  static const String name = 'StylistAppointmentsMainRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i23.StylistAppointmentsMainScreen();
    },
  );
}

/// generated route for
/// [_i24.StylistBusinessIdVerifyScreen]
class StylistBusinessIdVerifyRoute
    extends _i29.PageRouteInfo<StylistBusinessIdVerifyRouteArgs> {
  StylistBusinessIdVerifyRoute({
    _i30.Key? key,
    bool fromSignUp = false,
    List<_i29.PageRouteInfo>? children,
  }) : super(
          StylistBusinessIdVerifyRoute.name,
          args: StylistBusinessIdVerifyRouteArgs(
            key: key,
            fromSignUp: fromSignUp,
          ),
          initialChildren: children,
        );

  static const String name = 'StylistBusinessIdVerifyRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StylistBusinessIdVerifyRouteArgs>(
        orElse: () => const StylistBusinessIdVerifyRouteArgs(),
      );
      return _i29.WrappedRoute(
        child: _i24.StylistBusinessIdVerifyScreen(
          key: args.key,
          fromSignUp: args.fromSignUp,
        ),
      );
    },
  );
}

class StylistBusinessIdVerifyRouteArgs {
  const StylistBusinessIdVerifyRouteArgs({this.key, this.fromSignUp = false});

  final _i30.Key? key;

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
/// [_i25.StylistMoreInfoScreen]
class StylistMoreInfoRoute extends _i29.PageRouteInfo<void> {
  const StylistMoreInfoRoute({List<_i29.PageRouteInfo>? children})
      : super(StylistMoreInfoRoute.name, initialChildren: children);

  static const String name = 'StylistMoreInfoRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i25.StylistMoreInfoScreen();
    },
  );
}

/// generated route for
/// [_i26.StylistProfileScreen]
class StylistProfileRoute extends _i29.PageRouteInfo<void> {
  const StylistProfileRoute({List<_i29.PageRouteInfo>? children})
      : super(StylistProfileRoute.name, initialChildren: children);

  static const String name = 'StylistProfileRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i26.StylistProfileScreen();
    },
  );
}

/// generated route for
/// [_i27.StylistsMainScreen]
class StylistsMainRoute extends _i29.PageRouteInfo<void> {
  const StylistsMainRoute({List<_i29.PageRouteInfo>? children})
      : super(StylistsMainRoute.name, initialChildren: children);

  static const String name = 'StylistsMainRoute';

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      return const _i27.StylistsMainScreen();
    },
  );
}

/// generated route for
/// [_i28.VerifyEmailScreen]
class VerifyEmailRoute extends _i29.PageRouteInfo<VerifyEmailRouteArgs> {
  VerifyEmailRoute({
    required String email,
    bool asStylist = false,
    _i30.Key? key,
    List<_i29.PageRouteInfo>? children,
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

  static _i29.PageInfo page = _i29.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VerifyEmailRouteArgs>();
      return _i29.WrappedRoute(
        child: _i28.VerifyEmailScreen(
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

  final _i30.Key? key;

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
