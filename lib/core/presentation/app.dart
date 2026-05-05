import 'dart:developer';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/app_config/app_state_guard.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/routing/routes.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/appointments/customer_appointments/cubit/customer_appointments_cubit.dart';
import 'package:snip_fair/features/appointments/stylist_appointments/cubit/seller_appoint_mgt_cubit.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/features/notifications/cubit/notifications_cubit.dart';
import 'package:snip_fair/features/onboarding/views/splash_screen.dart';
import 'package:snip_fair/l10n/arb/app_localizations.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = getIt<AppRouter>();
    _setupNotificationNavigation();
  }

  /// Sets up the notification tap handler with auth checks and role-based routing.
  /// This is called in initState() after AppCubit is created, so the cubit
  /// is available when notifications are tapped (not during bootstrap initialization).
  void _setupNotificationNavigation() {
    NotificationService.instance.onNotificationTap =
        (Map<String, dynamic> data) {
      log('Notification tapped with data: $data');

      // Get AppCubit - accesses current state when notification is tapped
      final appCubit = getIt<AppCubit>();
      final state = appCubit.state;

      // Check if user is authenticated
      if (state.status != AuthStatus.authenticated) {
        log('User not authenticated, ignoring notification navigation');
        return;
      }

      // Extract notification data
      final type = data['type'] as String?;
      final typeIdentifier = data['type_identifier'];

      if (type == null || type.isEmpty) {
        log('Notification type is null or empty');
        return;
      }

      // Route based on notification type and user role
      try {
        switch (type) {
          case 'chat':
          case 'message':
            // Navigate to chat screen
            if (typeIdentifier != null) {
              _appRouter.push(
                ConvesationChatRoute(
                  conversationId: typeIdentifier.toString(),
                  currentUserId: state.user.id.toString(),
                ),
              );
            }

          case 'appointment':
            // Different routes for stylists vs customers
            if (typeIdentifier != null) {
              if (state.isStylist) {
                _appRouter.push(
                  SellerAppointmentDetailsRoute(
                    appointmentId: typeIdentifier.toString(),
                  ),
                );
              } else if (state.isCustomer) {
                // Navigate to customer appointments calendar
                _appRouter.push(const CustomerAppointmentsCalendarRoute());
              }
            }

          case 'booking':
            // Handle booking notifications
            if (state.isStylist) {
              // Navigate to stylist appointments
              _appRouter.push(const AppointementsMainRoute());
            } else if (state.isCustomer) {
              // Navigate to customer appointments
              _appRouter.push(const CustomerAppointmentsCalendarRoute());
            }

          case 'payment':
          case 'wallet':
            // Navigate to wallet (customers only)
            if (state.isCustomer) {
              _appRouter.push(const CustomerWalletRoute());
            }

          case 'dispute':
            // Navigate to disputes
            _appRouter.push(const DisputesRoute());

          case 'notification':
          case 'general':
            // Navigate to notifications list
            _appRouter.push(const NotificationsRoute());

          default:
            log('Unknown notification type: $type');
            // Default: navigate to notifications list
            _appRouter.push(const NotificationsRoute());
        }
      } catch (e, stackTrace) {
        log('Error navigating from notification: $e', stackTrace: stackTrace);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AppCubit>()..onAppStarted(),
      child: BlocProvider(
        create: (context) => getIt<SellerProfileMgtCubit>(),
        child: BlocProvider(
          create: (context) => getIt<CustomerProfileMgtCubit>(),
          child: BlocProvider(
            create: (context) =>
                getIt<ConversationsCubit>()..fetchConversations(),
            child: BlocProvider(
              create: (context) =>
                  getIt<CustomerAppointmentsCubit>()..getAppointments(),
              child: BlocProvider(
                create: (context) =>
                    getIt<SellerAppointMgtCubit>()..getAppointments(),
                child: BlocProvider(
                  create: (context) => getIt<NotificationsCubit>()
                    ..fetchNotifications(
                      isInitial: true,
                    )
                    ..startListeningForNotifications(),
                  child: CalendarControllerProvider(
                    controller: EventController(),
                    child: ScreenUtilInit(
                      designSize: const Size(402, 874),
                      minTextAdapt: true,
                      builder: (__, _) {
                        return MaterialApp.router(
                          routeInformationParser:
                              _appRouter.defaultRouteParser(),
                          routerDelegate: _appRouter.delegate(),
                          debugShowCheckedModeBanner: false,
                          theme: AppTheme.lightTheme,
                          darkTheme: AppTheme.darkTheme,
                          themeMode: ThemeMode.light,
                          localizationsDelegates:
                              AppLocalizations.localizationsDelegates,
                          supportedLocales: AppLocalizations.supportedLocales,
                          builder: (context, child) {
                            return AppStateGuard(
                              child: BlocConsumer<AppCubit, AppState>(
                                listenWhen: (previous, current) =>
                                    previous.status != current.status,
                                listener: (context, state) {
                                  switch (state.status) {
                                    case AuthStatus.unknown:
                                      break;
                                    case AuthStatus.unAuthenticated:
                                      _appRouter
                                          .replaceAll([const LandingRoute()]);
                                      context
                                          .read<SellerProfileMgtCubit>()
                                          .onLogout();
                                      context
                                          .read<CustomerProfileMgtCubit>()
                                          .onLogout();
                                      context
                                          .read<ConversationsCubit>()
                                          .onLogout();
                                      context
                                          .read<CustomerAppointmentsCubit>()
                                          .onLogout();
                                      context
                                          .read<SellerAppointMgtCubit>()
                                          .onLogout();
                                      context
                                          .read<NotificationsCubit>()
                                          .onLogout();

                                    case AuthStatus.authenticated:
                                      if (state.user.emailVerifiedAt == null) {
                                        _appRouter.replaceAll([
                                          const LandingRoute(),
                                          VerifyEmailRoute(
                                            email: state.user.email!,
                                            asStylist: state.isStylist,
                                          ),
                                        ]);
                                        return;
                                      }

                                      if (state.isStylist &&
                                          state.user.stylistProfile
                                                  ?.businessName ==
                                              null) {
                                        _appRouter.replaceAll([
                                          const LandingRoute(),
                                          SellerBusinessCreateRoute(
                                            fromSignUp: true,
                                          ),
                                        ]);
                                        return;
                                      }

                                      if (state.isStylist &&
                                          state.user.stylistProfile
                                                  ?.identificationId ==
                                              null) {
                                        _appRouter.replaceAll([
                                          const LandingRoute(),
                                          StylistBusinessIdVerifyRoute(
                                            fromSignUp: true,
                                          ),
                                        ]);
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

                                      _appRouter
                                          .replaceAll([const MainRoute()]);
                                    case AuthStatus.guest:
                                      _appRouter
                                          .replaceAll([const MainRoute()]);
                                  }
                                },
                                builder: (context, state) {
                                  if (state.status == AuthStatus.unknown) {
                                    return const SplashScreen();
                                  }
                                  return child!;
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
