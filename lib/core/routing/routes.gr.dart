// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i12;
import 'package:flutter/material.dart' as _i13;
import 'package:snip_fair/core/presentation/main_screen.dart' as _i7;
import 'package:snip_fair/features/account/views/account_main_screen.dart'
    as _i1;
import 'package:snip_fair/features/appointments/views/appointements_main_screen.dart'
    as _i2;
import 'package:snip_fair/features/authentication/forgot_password/views/forgot_password_screen.dart'
    as _i4;
import 'package:snip_fair/features/authentication/login/views/login_screen.dart'
    as _i6;
import 'package:snip_fair/features/authentication/signup/views/signup_screen.dart'
    as _i8;
import 'package:snip_fair/features/authentication/verify_email/views/verify_email_screen.dart'
    as _i11;
import 'package:snip_fair/features/explore/views/explore_main_screen.dart'
    as _i3;
import 'package:snip_fair/features/onboarding/views/landing_screen.dart' as _i5;
import 'package:snip_fair/features/onboarding/views/splash_screen.dart' as _i9;
import 'package:snip_fair/features/stylists/views/stylists_main_screen.dart'
    as _i10;

/// generated route for
/// [_i1.AccountMainScreen]
class AccountMainRoute extends _i12.PageRouteInfo<void> {
  const AccountMainRoute({List<_i12.PageRouteInfo>? children})
      : super(AccountMainRoute.name, initialChildren: children);

  static const String name = 'AccountMainRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i1.AccountMainScreen();
    },
  );
}

/// generated route for
/// [_i2.AppointementsMainScreen]
class AppointementsMainRoute extends _i12.PageRouteInfo<void> {
  const AppointementsMainRoute({List<_i12.PageRouteInfo>? children})
      : super(AppointementsMainRoute.name, initialChildren: children);

  static const String name = 'AppointementsMainRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i2.AppointementsMainScreen();
    },
  );
}

/// generated route for
/// [_i3.ExploreMainScreen]
class ExploreMainRoute extends _i12.PageRouteInfo<void> {
  const ExploreMainRoute({List<_i12.PageRouteInfo>? children})
      : super(ExploreMainRoute.name, initialChildren: children);

  static const String name = 'ExploreMainRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i3.ExploreMainScreen();
    },
  );
}

/// generated route for
/// [_i4.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i12.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i12.PageRouteInfo>? children})
      : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return _i12.WrappedRoute(child: const _i4.ForgotPasswordScreen());
    },
  );
}

/// generated route for
/// [_i5.LandingScreen]
class LandingRoute extends _i12.PageRouteInfo<void> {
  const LandingRoute({List<_i12.PageRouteInfo>? children})
      : super(LandingRoute.name, initialChildren: children);

  static const String name = 'LandingRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i5.LandingScreen();
    },
  );
}

/// generated route for
/// [_i6.LoginScreen]
class LoginRoute extends _i12.PageRouteInfo<void> {
  const LoginRoute({List<_i12.PageRouteInfo>? children})
      : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return _i12.WrappedRoute(child: const _i6.LoginScreen());
    },
  );
}

/// generated route for
/// [_i7.MainScreen]
class MainRoute extends _i12.PageRouteInfo<void> {
  const MainRoute({List<_i12.PageRouteInfo>? children})
      : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i7.MainScreen();
    },
  );
}

/// generated route for
/// [_i8.SignupScreen]
class SignupRoute extends _i12.PageRouteInfo<void> {
  const SignupRoute({List<_i12.PageRouteInfo>? children})
      : super(SignupRoute.name, initialChildren: children);

  static const String name = 'SignupRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return _i12.WrappedRoute(child: const _i8.SignupScreen());
    },
  );
}

/// generated route for
/// [_i9.SplashScreen]
class SplashRoute extends _i12.PageRouteInfo<void> {
  const SplashRoute({List<_i12.PageRouteInfo>? children})
      : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i9.SplashScreen();
    },
  );
}

/// generated route for
/// [_i10.StylistsMainScreen]
class StylistsMainRoute extends _i12.PageRouteInfo<void> {
  const StylistsMainRoute({List<_i12.PageRouteInfo>? children})
      : super(StylistsMainRoute.name, initialChildren: children);

  static const String name = 'StylistsMainRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i10.StylistsMainScreen();
    },
  );
}

/// generated route for
/// [_i11.VerifyEmailScreen]
class VerifyEmailRoute extends _i12.PageRouteInfo<VerifyEmailRouteArgs> {
  VerifyEmailRoute({
    required String email,
    _i13.Key? key,
    List<_i12.PageRouteInfo>? children,
  }) : super(
          VerifyEmailRoute.name,
          args: VerifyEmailRouteArgs(email: email, key: key),
          initialChildren: children,
        );

  static const String name = 'VerifyEmailRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VerifyEmailRouteArgs>();
      return _i12.WrappedRoute(
        child: _i11.VerifyEmailScreen(email: args.email, key: args.key),
      );
    },
  );
}

class VerifyEmailRouteArgs {
  const VerifyEmailRouteArgs({required this.email, this.key});

  final String email;

  final _i13.Key? key;

  @override
  String toString() {
    return 'VerifyEmailRouteArgs{email: $email, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VerifyEmailRouteArgs) return false;
    return email == other.email && key == other.key;
  }

  @override
  int get hashCode => email.hashCode ^ key.hashCode;
}
