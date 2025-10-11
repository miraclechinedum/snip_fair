import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/features/account/earnings/cubit/earnings_cubit.dart';
import 'package:snip_fair/features/account/earnings/views/seller_payout_settings_form_view.dart';

@RoutePage()
class SellerEarningScreen extends StatelessWidget implements AutoRouteWrapper {
  const SellerEarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EarningsCubit>();
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Earnings',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await cubit.getEarnings();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: AppColors.appgradient,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      text: 'Total Earned',
                      color: Colors.white,
                    ),
                    8.verticalSpace,
                    AppText(
                      text: cubit.state.earnings.isLoading
                          ? '********'
                          : cubit.state.earnings.data?.statistics?.totalEarnings
                                  ?.value
                                  ?.formatAmount() ??
                              '0',
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              12.verticalSpace,
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: AppColors.grey1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: 'Available Balance',
                      color: Colors.grey.shade600,
                    ),
                    8.verticalSpace,
                    AppText(
                      text: cubit.state.earnings.isLoading
                          ? '********'
                          : cubit.state.earnings.data?.statistics?.totalBalance
                                  ?.value
                                  ?.formatAmount() ??
                              '0',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              12.verticalSpace,
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: AppColors.grey1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: 'Total Withdrawn',
                      color: Colors.grey.shade600,
                    ),
                    8.verticalSpace,
                    AppText(
                      text: cubit.state.earnings.isLoading
                          ? '********'
                          : cubit.state.earnings.data?.statistics
                                  ?.totalWithdrawn?.value
                                  ?.formatAmount() ??
                              '0',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              12.verticalSpace,
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: AppColors.grey1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: 'Pending Requests',
                      color: Colors.grey.shade600,
                    ),
                    8.verticalSpace,
                    AppText(
                      text: cubit.state.earnings.isLoading
                          ? '********'
                          : cubit.state.earnings.data?.statistics?.totalRequests
                                  ?.value
                                  ?.toString() ??
                              '0',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              12.verticalSpace,
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: AppColors.grey1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppText(
                          text: 'Payout Settings',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        AppText(
                          text: cubit.state.settings?.instantPayout != null
                              ? cubit.state.settings!.instantPayout!
                                  ? 'Manaul Payout'
                                  : 'Automatic Payout'
                              : '',
                          fontSize: 12,
                        )
                      ],
                    ),
                    const Divider(),
                    if (cubit.state.earnings.data?.paymentMethod == null)
                      const AppText(text: 'No Payment method')
                    else ...[
                      ListTile(
                        minLeadingWidth: 10,
                       
                        leading: const Icon(
                          Iconsax.card,
                          size: 15,
                          color: Color(0xffDB297A),
                        ),
                        title: AppText(
                          text: cubit.state.earnings.data!.paymentMethod!
                                  .bankName ??
                              '',
                        ),
                        subtitle: AppText(
                          text:
                              'Routing: ${cubit.state.earnings.data!.paymentMethod!.routingNumber} \nAccount: ${cubit.state.earnings.data!.paymentMethod!.accountNumber.showLast4Digits()}',
                          fontSize: 12,
                          color: AppColors.grey3,
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            context.pushRoute(
                              const SellerPaymentMethodsRoute(),
                            );
                          },
                          child: const Icon(
                            Iconsax.edit_2,
                            size: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      12.verticalSpace,
                      Builder(
                        builder: (context) {
                          return TextButton.icon(
                            icon: const Icon(
                              Iconsax.setting,
                              size: 15,
                            ),
                            onPressed: () {
                              SellerPayoutSettingsFormWidget.show(context);
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ),
                              ),
                              textStyle: AppTextStyle.caption
                                  .copyWith(fontWeight: FontWeight.w600),
                              foregroundColor: AppColors.black,
                              backgroundColor: const Color(0xffF6F7F8),
                            ),
                            label: const Text('Change Settings'),
                          );
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<EarningsCubit>()..getEarnings(),
      child: this,
    );
  }
}
