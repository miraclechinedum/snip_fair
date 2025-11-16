import 'dart:async';
import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';

import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/support_webview_widget.dart';
import 'package:snip_fair/core/routing/routes.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/services/location_service.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/features/notifications/cubit/notifications_cubit.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final locationService = getIt<LocationService>();
  final notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    NotificationService.instance.onNotificationTap =
        (Map<String, dynamic> data) {
      final appRouter = getIt<AppRouter>();
      log('Notification tapped with data: $data');

      // Get AppCubit - it's available through the widget tree at this point
      final appCubit = context.read<AppCubit>();
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
          case 'conversation':
            // Navigate to chat screen
            if (typeIdentifier != null) {
              appRouter.push(
                ConvesationChatRoute(
                  conversationId: typeIdentifier.toString(),
                  currentUserId: state.user.id.toString(),
                ),
              );
            }
            break;

          case 'appointment':
            // Different routes for stylists vs customers
            if (typeIdentifier != null) {
              if (state.isStylist) {
                appRouter.push(
                  SellerAppointmentDetailsRoute(
                    appointmentId: typeIdentifier.toString(),
                  ),
                );
              } else if (state.isCustomer) {
                // Navigate to customer appointments calendar
                appRouter.push(UpdateCreateAppointmentRoute(
                    appointmentId: typeIdentifier.toString()));
              }
            }
            break;

          case 'payment':
          case 'wallet':
            // Navigate to wallet (customers only)
            if (state.isCustomer) {
              appRouter.push(const CustomerWalletRoute());
            } else {
              appRouter.push(const SellerEarningRoute());
            }
            break;

          case 'dispute':
            // Navigate to disputes
            final token = getIt<LocalKeyStorage>().accessToken;
            if (token == null) return;
            final supportUrl =
                Environment().config.apiHost.replaceAll('api', 'disputes');
            context.router.pushWidget(
              SupportWebViewWidget(
                supportUrl: supportUrl,
                authToken: token,
              ),
            );
            break;

          case 'notification':
          case 'general':
            // Navigate to notifications list
            appRouter.push(const NotificationsRoute());
            break;

          default:
            log('Unknown notification type: $type');
            // Default: navigate to notifications list
            appRouter.push(const NotificationsRoute());
        }
      } catch (e, stackTrace) {
        log('Error navigating from notification: $e', stackTrace: stackTrace);
      }
    };
  }

  Future<void> _checkLocationPermission() async {
    final appCubit = context.read<AppCubit>();
    final hasPermission = await locationService.checkLocationPermission();
    if (!hasPermission && mounted) {
      var consentGiven = await LocationPermissionBottomSheet.show(
        context,
        subtitle: appCubit.state.isStylist
            ? 'Allow the app to access your device location so we can recommend you to nearby clients.'
            : 'Allow the app to access your device location so we can show nearby stylists and appointments.',
      );
      consentGiven ??= false;
      locationService.sendConsentToUseLocation(consentGiven);
      if (consentGiven) {
        final permissionGranted =
            await locationService.requestLocationPermission();

        if (permissionGranted) {
          locationService.sendLocationUpdateRequest();
        } else {
          unawaited(locationService.openLocationSettings());
          Fluttertoast.showToast(
            msg: 'Location permission is required to use this feature.',
          );
        }
      }
    } else {
      locationService.sendLocationUpdateRequest();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppCubit>().state;
    return AutoTabsScaffold(
      appBarBuilder: (context, tabsRouter) {
        if (appState.isStylist) {
          if (tabsRouter.activeIndex == 2) {
            return PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(),
            );
          }
        } else {
          if (tabsRouter.activeIndex == 3) {
            return PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(),
            );
          }

          if (tabsRouter.activeIndex == 1) {
            return PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(),
            );
          }
        }

        return AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          title: SvgPicture.asset(
            Assets.images.logoText,
            width: 120,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () {
                context.read<ConversationsCubit>().fetchConversations();
                context.router.push(ConversationListRoute());
              },
              icon: const Icon(
                Iconsax.message,
                color: AppColors.primaryColor,
              ),
            ),
            IconButton(
              onPressed: () {
                context
                    .read<NotificationsCubit>()
                    .fetchNotifications(isInitial: true);
                context.router.push(const NotificationsRoute());
              },
              icon: const Icon(
                Iconsax.notification,
                color: AppColors.primaryColor,
              ),
            ),
            12.horizontalSpace,
          ],
        );
      },
      routes: appState.isStylist
          ? const [
              SellerDashboardMainRoute(),
              SellerAppointmentsMainRoute(),
              AccountMainRoute(),
            ]
          : const [
              ExploreMainRoute(),
              SearchMainRoute(),
              AppointementsMainRoute(),
              AccountMainRoute(),
            ],
      bottomNavigationBuilder: (context, tabsRouter) {
        final items = appState.isStylist
            ? [
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.menu_board),
                  label: 'Dashboard',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.calendar),
                  label: 'Appointments',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.setting_44),
                  label: 'Menu',
                ),
              ]
            : [
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.home),
                  label: 'Explore',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.search_normal),
                  label: 'Search',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.calendar),
                  label: 'Appointments',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.setting_44),
                  label: 'Menu',
                ),
              ];
        return BottomNavigationBar(
          items: items,
          selectedLabelStyle:
              AppTextStyle.caption.copyWith(fontWeight: FontWeight.w600),
          currentIndex: tabsRouter.activeIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryColor,
          backgroundColor: AppColors.white,
          onTap: (index) => tabsRouter.setActiveIndex(index),
        );
      },
    );
  }
}

class CustomBarItem extends StatelessWidget {
  const CustomBarItem({
    required this.label,
    required this.iconPath,
    required this.isActive,
    super.key,
    this.onTap,
  });

  final void Function()? onTap;
  final String label;
  final String iconPath;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kThemeAnimationDuration,
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkGrey100 : null,
          borderRadius: BorderRadius.circular(16).r,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              colorFilter: ColorFilter.mode(
                isActive ? AppColors.primaryColor : AppColors.darkGrey700,
                BlendMode.srcIn,
              ),
            ),
            6.verticalSpace,
            AppText(
              text: label,
              fontSize: 12,
              color: isActive ? AppColors.primaryColor : AppColors.darkGrey700,
            ),
          ],
        ),
      ),
    );
  }
}

class LocationPermissionBottomSheet extends StatelessWidget {
  const LocationPermissionBottomSheet({
    super.key,
    this.onAllow,
    this.onDeny,
    this.title = 'Enable location sharing',
    this.subtitle =
        'Allow the app to access your device location so we can show nearby results and appointments.',
  });

  final VoidCallback? onAllow;
  final VoidCallback? onDeny;
  final String title;
  final String subtitle;

  /// Convenience helper to display the sheet and receive a bool result:
  /// true = allowed, false = denied, null = dismissed.
  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onAllow,
    VoidCallback? onDeny,
    String? title,
    String? subtitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => LocationPermissionBottomSheet(
        onAllow: onAllow,
        onDeny: onDeny,
        title: title ?? 'Enable location sharing',
        subtitle: subtitle ??
            'Allow the app to access your device location so we can show nearby results and appointments.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: const Radius.circular(16).r),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.darkGrey100,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            16.verticalSpace,
            Icon(
              Icons.location_on,
              size: 56.r,
              color: AppColors.primaryColor,
            ),
            12.verticalSpace,
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  AppTextStyle.headline4.copyWith(fontWeight: FontWeight.w700),
            ),
            8.verticalSpace,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle.subTitle2.copyWith(
                color: AppColors.darkGrey700,
              ),
            ),
            20.verticalSpace,
            CustomButton(
              title: 'Allow location',
              onPressed: () {
                Navigator.of(context).pop(true);
                onAllow?.call();
              },
            ),
            8.verticalSpace,
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  onDeny?.call();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: const BorderSide(color: AppColors.darkGrey100),
                  ),
                ),
                child: Text(
                  'Not now',
                  style: AppTextStyle.subTitle2.copyWith(
                    color: AppColors.darkGrey700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
