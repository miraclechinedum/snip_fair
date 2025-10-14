import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/routing/routes.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/onboarding/views/splash_screen.dart';
import 'package:snip_fair/l10n/arb/app_localizations.dart';
import 'package:snip_fair/l10n/l10n.dart';

final appRouter = AppRouter();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AppCubit>()..onAppStarted(),
      child: BlocProvider(
        create: (context) => getIt<SellerProfileMgtCubit>(),
        child: BlocProvider(
          create: (context) => getIt<CustomerProfileMgtCubit>(),
          child: CalendarControllerProvider(
            controller: EventController(),
            child: ScreenUtilInit(
              designSize: const Size(402, 874),
              minTextAdapt: true,
              builder: (__, _) {
                return MaterialApp.router(
                  routeInformationParser: appRouter.defaultRouteParser(),
                  routerDelegate: appRouter.delegate(),
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: ThemeMode.light,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) {
                    return BlocConsumer<AppCubit, AppState>(
                      listenWhen: (previous, current) =>
                          previous.status != current.status,
                      listener: (context, state) {
                        switch (state.status) {
                          case AuthStatus.unknown:
                            break;
                          case AuthStatus.unAuthenticated:
                            appRouter.pushAndPopUntil(
                              const LandingRoute(),
                              predicate: (route) => false,
                            );
                          case AuthStatus.authenticated:
                            if (state.user.emailVerifiedAt == null) {
                              appRouter.push(
                                VerifyEmailRoute(
                                  email: state.user.email!,
                                  asStylist: state.isStylist,
                                ),
                              );
                              return;
                            }

                            if (state.isStylist &&
                                state.user.stylistProfile?.businessName ==
                                    null) {
                              appRouter.push(
                                SellerBusinessCreateRoute(
                                  fromSignUp: true,
                                ),
                              );
                              return;
                            }

                            if (state.isStylist &&
                                state.user.stylistProfile?.identificationId ==
                                    null) {
                              appRouter.push(
                                StylistBusinessIdVerifyRoute(
                                  fromSignUp: true,
                                ),
                              );
                              return;
                            }

                            if (state.isStylist) {
                              context.read<SellerProfileMgtCubit>()
                                ..getProfileDetails()
                                ..getStats();
                            }

                            if (state.isCustomer) {
                              context.read<CustomerProfileMgtCubit>()
                                ..getProfileDetails()
                                ..getStats()
                                ..getWallet()
                                ..getWalletTransactions();
                            }

                            appRouter.pushAndPopUntil(
                              const MainRoute(),
                              predicate: (route) => false,
                            );
                        }
                      },
                      builder: (context, state) {
                        if (state.status == AuthStatus.unknown) {
                          return const SplashScreen();
                        }
                        return child!;
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
