import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/profile_management/views/seller_profile_management_screen.dart';
import 'package:snip_fair/features/account/profile_verification/views/seller_profile_verification_screen.dart';

@RoutePage()
class AccountMainScreen extends StatelessWidget {
  const AccountMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isStylist =
        context.select<AppCubit, bool>((cubit) => cubit.state.isStylist);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            BlocBuilder<AppCubit, AppState>(
              builder: (context, state) {
                if (state.status != AuthStatus.authenticated)
                  return const SizedBox();
                if (state.isStylist) {
                  return _buildStylistProfileHeader(context);
                }
                return _buildCustomerProfileHeader(state);
              },
            ),
            if (isStylist) ...[
              ListTile(
                leading: const Icon(Iconsax.personalcard),
                title: const AppText(
                  text: 'Account',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  if (AppHelper.isStylist(context)) {
                    context.router.push(const SellerProfileManagementRoute());
                  } else {
                    context.router.push(const PersonalDetailsRoute());
                  }
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.bag_2),
                title: const AppText(
                  text: 'Portfolio',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const SellerPortfolioRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery5),
                title: const AppText(
                  text: 'Media',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.router.push(SellerWorkRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.dollar_square),
                title: const AppText(
                  text: 'Earning',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const SellerEarningRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.star_1),
                title: const AppText(
                  text: 'Availability',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const SellerAvailabilityScheduleRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.password_check),
                title: const AppText(
                  text: 'Change password',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const ChangePasswordRoute());
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Iconsax.password_check),
                title: const AppText(
                  text: 'Change password',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const ChangePasswordRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.wallet),
                title: const AppText(
                  text: 'Wallet',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Iconsax.heart_tick),
                title: const AppText(
                  text: 'My Favorites',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {},
              ),
            ],
            ListTile(
              leading: const Icon(Iconsax.message_question),
              title: const AppText(
                text: 'Support',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Iconsax.logout4,
                color: Colors.red,
              ),
              title: const AppText(
                text: 'Logout',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
              onTap: () {
                context.read<AppCubit>().onLogout();
              },
            ),
            24.verticalSpace,
            // BlocBuilder<AppCubit, AppState>(
            //   builder: (context, state) {
            //     if (state.isCustomer) {
            //       return Padding(
            //         padding: const EdgeInsets.symmetric(horizontal: 16),
            //         child: CustomButton(
            //           title: 'Become a Stylist',
            //           onPressed: () {
            //             context.router.push(StylistBusinessCreateRoute());
            //           },
            //         ),
            //       );
            //     }
            //     return SizedBox();
            //   },
            // )
          ],
        ),
      ),
    );
  }

  Widget _buildStylistProfileHeader(BuildContext context) {
    return BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => context.pushRoute(const SellerProfileManagementRoute()),
          child: Container(
            margin: const EdgeInsets.all(16),
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
                  children: [
                    SellerProfileAvatar(
                      profileDetails: state.profileDetails.data,
                    ),
                    10.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text:
                                state.profileDetails.data?.user?.name ?? 'N/A',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          AppText(
                            text: state.profileDetails.data?.user
                                    ?.stylistProfile?.businessName ??
                                'N/A',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              5.horizontalSpace,
                              AppText(
                                text: state.profileDetails.data?.statistics
                                        ?.averageRating
                                        ?.toString() ??
                                    '0',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              5.horizontalSpace,
                              AppText(
                                text:
                                    '(${state.profileDetails.data?.statistics?.totalReviews?.toString() ?? '0'} Reviews)',
                                fontSize: 12,
                                color: AppColors.grey3,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      12.horizontalSpace,
                      const AppText(
                        text: 'Availability',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 35,
                        child: Switch(
                          value: state.profileDetails.data?.user?.stylistProfile
                                  ?.isAvailable ??
                              false,
                          onChanged: (value) {
                            if (state.profileDetails.data?.profileCompleteness
                                    ?.statusApproved ??
                                false) {
                            } else {
                              AppHelper.showSnackBar(context,
                                  message:
                                      'You need to have an active stylist profile to change your availability.');
                            }
                          },
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Container _buildCustomerProfileHeader(AppState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.appgradient,
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            child: AppText(
              text: state.user.name!.split(' ').first[0].toUpperCase() +
                  state.user.name!.split(' ').last[0].toUpperCase(),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          10.verticalSpace,
          AppText(
            text: state.user.name ?? 'N/A',
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          AppText(
            text: state.user.email ?? 'N/A',
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
