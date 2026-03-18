import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/preferences.dart';
import 'package:snip_fair/features/account/customer/preferences/cubit/customer_prefs_settings_cubit.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';

@RoutePage()
class CustomerPreferencesScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const CustomerPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CustomerPrefsSettingsCubit>();
    final state = cubit.state;
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Preferences',
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
                        text: 'Booking Preferences',
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      const AppText(
                        text: 'Preferred Service Time',
                        fontSize: 12,
                      ),
                      5.verticalSpace,
                      DropdownButtonFormField<ServiceTime>(
                        initialValue: state.preferences?.preferredTime != null
                            ? ServiceTime.values.firstWhere(
                                (e) =>
                                    e.name == state.preferences!.preferredTime,
                                orElse: () => ServiceTime.morning,
                              )
                            : null,
                        items: ServiceTime.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final updatedPrefs = state.preferences!.copyWith(
                            preferredTime: value.name,
                          );
                          cubit.setPreferences(updatedPrefs);
                        },
                        decoration: AppColors.inputDecoration.copyWith(
                          hintText: 'Preferred Service Time',
                        ),
                      ),
                      12.verticalSpace,
                      const AppText(
                        text: 'Preferred Stylist Gender',
                        fontSize: 12,
                      ),
                      5.verticalSpace,
                      DropdownButtonFormField<StylistGender>(
                        initialValue:
                            state.preferences?.preferredStylist != null
                                ? StylistGender.values.firstWhere(
                                    (e) =>
                                        e.name ==
                                        state.preferences!.preferredStylist,
                                    orElse: () => StylistGender.none,
                                  )
                                : null,
                        items: StylistGender.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final updatedPrefs = state.preferences!.copyWith(
                            preferredStylist: value.name,
                          );
                          cubit.setPreferences(updatedPrefs);
                        },
                        decoration: AppColors.inputDecoration.copyWith(
                          hintText: 'Preferred Stylist Gender',
                        ),
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Auto-location',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text:
                              'Automatically use device location for booking appointments',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.preferences?.useLocation ?? false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.preferences == null) return;
                            final updatedPrefs = state.preferences!.copyWith(
                              useLocation: value,
                            );
                            cubit.setPreferences(updatedPrefs);
                          },
                        ),
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Auto-rebooking',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text:
                              'Automatically suggest rebooking based on your service history',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.preferences?.autoRebooking ?? false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.preferences == null) return;
                            final updatedPrefs = state.preferences!.copyWith(
                              autoRebooking: value,
                            );
                            cubit.setPreferences(updatedPrefs);
                          },
                        ),
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Mobile Stylist Services',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Include mobile stylists in search results',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.preferences?.enableMobileAppointment ??
                              false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.preferences == null) return;
                            final updatedPrefs = state.preferences!.copyWith(
                              enableMobileAppointment: value,
                            );
                            cubit.setPreferences(updatedPrefs);
                          },
                        ),
                      ),
                      12.verticalSpace,
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
                        text: 'Communication Preferences',
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Email Reminders',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Receive appointment reminders via email',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.preferences?.emailReminders ?? false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.preferences == null) return;
                            final updatedPrefs = state.preferences!.copyWith(
                              emailReminders: value,
                            );
                            cubit.setPreferences(updatedPrefs);
                          },
                        ),
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'SMS Reminders',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text:
                              'Receive appointment reminders via text message',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.preferences?.smsReminders ?? false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.preferences == null) return;
                            final updatedPrefs = state.preferences!.copyWith(
                              smsReminders: value,
                            );
                            cubit.setPreferences(updatedPrefs);
                          },
                        ),
                      ),
                      12.verticalSpace,
                      ListTile(
                        title: const AppText(
                          text: 'Phone Calls',
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        subtitle: const AppText(
                          text: 'Receive appointment reminders via phone call',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: Switch(
                          value: state.preferences?.phoneReminders ?? false,
                          activeThumbColor: Colors.green,
                          onChanged: (value) {
                            if (state.preferences == null) return;
                            final updatedPrefs = state.preferences!.copyWith(
                              phoneReminders: value,
                            );
                            cubit.setPreferences(updatedPrefs);
                          },
                        ),
                      ),
                      12.verticalSpace,
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
                        text: 'Regional Settings',
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      12.verticalSpace,
                      const AppText(
                        text: 'Language',
                        fontSize: 12,
                      ),
                      5.verticalSpace,
                      DropdownButtonFormField<PreferredLanguage>(
                        initialValue: state.preferences?.language != null
                            ? PreferredLanguage.values.firstWhere(
                                (e) => e.name == state.preferences!.language,
                                orElse: () => PreferredLanguage.english,
                              )
                            : null,
                        items: PreferredLanguage.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final updatedPrefs = state.preferences!.copyWith(
                            language: value.name,
                          );
                          cubit.setPreferences(updatedPrefs);
                        },
                        decoration: AppColors.inputDecoration.copyWith(
                          hintText: 'Preferred Service Time',
                        ),
                      ),
                      12.verticalSpace,
                      const AppText(
                        text: 'Currency',
                        fontSize: 12,
                      ),
                      5.verticalSpace,
                      DropdownButtonFormField<PreferredCurrency>(
                        initialValue: state.preferences?.currency != null
                            ? PreferredCurrency.values.firstWhere(
                                (e) => e.name == state.preferences!.currency,
                                orElse: () => PreferredCurrency.zar,
                              )
                            : null,
                        items: PreferredCurrency.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  '${e.symbol} - ${e.name.toUpperCase()}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final updatedPrefs = state.preferences!.copyWith(
                            currency: value.name,
                          );
                          cubit.setPreferences(updatedPrefs);
                        },
                        decoration: AppColors.inputDecoration.copyWith(
                          hintText: 'Preferred Service Time',
                        ),
                      ),
                    ],
                  ),
                ),
                12.verticalSpace,
                BlocConsumer<CustomerPrefsSettingsCubit,
                    CustomerPrefsSettingsState>(
                  listenWhen: (previous, current) =>
                      previous.updatePrefsState != current.updatePrefsState,
                  listener: (context, state) {
                    if (state.updatePrefsState.hasSuccess) {
                      context
                          .read<CustomerProfileMgtCubit>()
                          .getProfileDetails();
                      AppHelper.showSnackBar(
                        context,
                        message: 'Preferences settings updated successfully',
                      );
                      context.pop();
                    }

                    if (state.updatePrefsState.hasError) {
                      AppHelper.showSnackBar(
                        context,
                        message:
                            'Failed to update preferences settings. Please try again.',
                      );
                    }
                  },
                  builder: (context, state) {
                    return CustomButton(
                      title: 'Save Changes',
                      isLoading: state.updatePrefsState.isLoading,
                      onPressed: () {
                        context
                            .read<CustomerPrefsSettingsCubit>()
                            .updatePreferences();
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
        ?.preferences;
    return BlocProvider(
      create: (context) => getIt<CustomerPrefsSettingsCubit>()
        ..setPreferences(initialPrefs ?? Preferences()),
      child: this,
    );
  }
}
