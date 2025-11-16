import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/notifications.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/features/account/customer/notification_settings/cubit/customer_notif_settings_cubit.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';

@RoutePage()
class CustomerNotifSettingsScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const CustomerNotifSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CustomerNotifSettingsCubit>();
    final state = cubit.state;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notification Settings',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'Appointment Notifications',
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Booking Confirmations',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Get notified when appointments are confirmed',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value:
                              state.notificationSettings?.bookingConfirmation ??
                                  false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              bookingConfirmation: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                      ListTile(
                        title: const AppText(
                          text: 'Appointment Reminders',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Receive reminders before your appointments',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state
                                  .notificationSettings?.appointmentReminders ??
                              false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              appointmentReminders: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'Stylist & Service Updates',
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Favorite Stylist Updates',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'New availability from your favorite stylists',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.notificationSettings
                                  ?.favoriteStylistUpdate ??
                              false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              favoriteStylistUpdate: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                      ListTile(
                        title: const AppText(
                          text: 'Promotions & Offers',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Special deals and discounts',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.notificationSettings?.promotionsOffers ??
                              false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              promotionsOffers: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'Reviews & Feedback',
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Review Reminders',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text:
                              'Reminders to review your completed appointments',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.notificationSettings?.reviewReminders ??
                              false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              reviewReminders: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'Payment & Billing',
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Payment Confirmations',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Payment receipts and transaction updates',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state
                                  .notificationSettings?.paymentConfirmations ??
                              false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              paymentConfirmations: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'Work Confirmation Methods',
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Email Notifications',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Receive notifications via email',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value:
                              state.notificationSettings?.emailNotifications ??
                                  false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              emailNotifications: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                      ListTile(
                        title: const AppText(
                          text: 'Push Notifications',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Browser and app push notifications',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value:
                              state.notificationSettings?.pushNotifications ??
                                  false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              pushNotifications: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                      ListTile(
                        title: const AppText(
                          text: 'SMS Notifications',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Text message notifications',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.notificationSettings?.smsNotifications ??
                              false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.notificationSettings == null) return;
                            final updatedSettings =
                                state.notificationSettings!.copyWith(
                              smsNotifications: value,
                            );
                            cubit.setNotificationSettings(updatedSettings);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
                12.verticalSpace,
                BlocConsumer<CustomerNotifSettingsCubit,
                    CustomerNotifSettingsState>(
                  listenWhen: (previous, current) =>
                      previous.updateSettingsState !=
                      current.updateSettingsState,
                  listener: (context, state) {
                    if (state.updateSettingsState.hasSuccess) {
                      context
                          .read<CustomerProfileMgtCubit>()
                          .getProfileDetails();
                      AppHelper.showSnackBar(
                        context,
                        message: 'Notification settings updated successfully',
                      );
                      context.pop();
                    }

                    if (state.updateSettingsState.hasError) {
                      AppHelper.showSnackBar(
                        context,
                        message:
                            'Failed to update notification settings. Please try again.',
                      );
                    }
                  },
                  builder: (context, state) {
                    return CustomButton(
                      title: 'Save Changes',
                      isLoading: state.updateSettingsState.isLoading,
                      onPressed: () {
                        context
                            .read<CustomerNotifSettingsCubit>()
                            .updateNotificationSettings();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    final initialPrefs = context
        .read<CustomerProfileMgtCubit>()
        .state
        .profileDetails
        .data
        ?.notifications;
    return BlocProvider(
      create: (context) => getIt<CustomerNotifSettingsCubit>()
        ..setNotificationSettings(initialPrefs ?? Notifications()),
      child: this,
    );
  }
}
