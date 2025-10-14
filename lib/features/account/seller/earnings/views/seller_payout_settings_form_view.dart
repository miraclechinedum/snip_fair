import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/seller/availability/cubit/seller_availability_schedule_cubit.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

class SellerPayoutSettingsFormWidget extends StatelessWidget {
  const SellerPayoutSettingsFormWidget({super.key});

  static Future<void> show(BuildContext context) {
    return AppHelper.showCustomModalBottomSheet(
      context: context,
      modal: BlocProvider.value(
        value: context.read<EarningsCubit>(),
        child: const SellerPayoutSettingsFormWidget(),
      ),
      isDarkMode: false,
    )..whenComplete(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EarningsCubit>();
    return SafeArea(
      child: Column(
        children: [
          16.verticalSpace,
          const ModalPill(),
          12.verticalSpace,
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      text: 'Payout Settings',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    24.verticalSpace,
                    BlocBuilder<EarningsCubit, EarningsState>(
                      builder: (context, state) {
                        return ListTile(
                          title: const AppText(
                            text: 'Enable Automatic Payouts',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding: EdgeInsets.zero,
                          subtitle: const AppText(
                            text:
                                'Automatically transfer earnings to your bank account',
                            fontSize: 12,
                            color: AppColors.grey3,
                          ),
                          trailing: Switch(
                            value: state.settings?.automaticPayout ?? false,
                            onChanged: cubit.onAutomaticPayoutChanged,
                          ),
                        );
                      },
                    ),
                    BlocBuilder<EarningsCubit, EarningsState>(
                      builder: (context, state) {
                        return ListTile(
                          title: const AppText(
                            text: 'Use Manual Requests',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding: EdgeInsets.zero,
                          subtitle: const AppText(
                            text:
                                'Choose to submit your payment request at your convenience',
                            fontSize: 12,
                            color: AppColors.grey3,
                          ),
                          trailing: Switch(
                            value: state.settings?.instantPayout ?? false,
                            onChanged: cubit.onManualPayoutChanged,
                          ),
                        );
                      },
                    ),
                    12.verticalSpace,
                    const Divider(),
                    12.verticalSpace,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payout Frequency',
                          style: AppTextStyle.body1.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.black,
                          ),
                        ),
                        5.horizontalSpace,
                        Text(
                          '*',
                          style: AppTextStyle.body1.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.contentColorRed,
                          ),
                        ),
                      ],
                    ),
                    5.verticalSpace,
                    BlocBuilder<EarningsCubit, EarningsState>(
                      builder: (context, state) {
                        final freq = [
                          'daily',
                          'weekly',
                          'bi-weekly',
                          'monthly',
                        ];

                        return DropdownButtonFormField<String>(
                          value: state.settings?.payoutFrequency?.toLowerCase(),
                          isExpanded: true,
                          items: List.generate(freq.length, (index) {
                            return DropdownMenuItem<String>(
                              value: freq[index].toLowerCase(),
                              child: AppText(
                                text: freq[index].toUpperCase(),
                                fontSize: 16,
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              cubit.onPayoutFrequencyChanged(value);
                            }
                          },
                          style: AppTextStyle.body1.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: AppColors.inputDecoration
                              .copyWith(hintText: 'Select option'),
                        );
                      },
                    ),
                    12.verticalSpace,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day of Week',
                          style: AppTextStyle.body1.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.black,
                          ),
                        ),
                        5.horizontalSpace,
                        Text(
                          '*',
                          style: AppTextStyle.body1.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.contentColorRed,
                          ),
                        ),
                      ],
                    ),
                    5.verticalSpace,
                    BlocBuilder<EarningsCubit, EarningsState>(
                      builder: (context, state) {
                        final day = scheduleDays;

                        return DropdownButtonFormField<String>(
                          value: state.settings?.payoutDay?.toLowerCase(),
                          isExpanded: true,
                          items: List.generate(day.length, (index) {
                            return DropdownMenuItem<String>(
                              value: day[index].toLowerCase(),
                              child: AppText(
                                text: day[index].toUpperCase(),
                                fontSize: 16,
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              cubit.onPayoutDayChanged(value);
                            }
                          },
                          style: AppTextStyle.body1.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: AppColors.inputDecoration
                              .copyWith(hintText: 'Select option'),
                        );
                      },
                    ),
                    12.verticalSpace,
                    12.verticalSpace,
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.grey200,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: BlocListener<EarningsCubit, EarningsState>(
              listenWhen: (previous, current) =>
                  previous.updatePayoutSettingState !=
                  current.updatePayoutSettingState,
              listener: (context, state) {
                if (state.updatePayoutSettingState.hasSuccess) {
                  context.read<SellerProfileMgtCubit>().getProfileDetails(true);
                  Navigator.pop(context);
                }

                if (state.updatePayoutSettingState.hasError) {
                  Navigator.pop(context);
                  AppHelper.showAppDialog<void>(
                    context,
                    OnFailDialogContent(
                      subtext: (state.updatePayoutSettingState.error!
                                  as RemoteException)
                              .errorResponse
                              ?.message ??
                          '',
                      onDoneCallback: (_) {},
                    ),
                  );
                }
              },
              child: CustomButton(
                isLoading: cubit.state.updatePayoutSettingState.isLoading,
                title: 'Save Changes',
                onPressed: cubit.state.settings != null
                    ? cubit.updatePayoutSettings
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
