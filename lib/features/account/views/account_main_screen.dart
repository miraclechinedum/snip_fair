import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/widgets/support_webview_widget.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_management/views/seller_profile_management_screen.dart';
import 'package:snip_fair/features/account/seller/shared/profile_completeness_compact_view.dart';

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
                if (state.status != AuthStatus.authenticated) {
                  return const SizedBox();
                }
                if (state.isStylist) {
                  return _buildStylistProfileHeader(context);
                }
                return _buildCustomerProfileHeader(context);
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
                  } else {}
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.bag_2),
                title: const AppText(
                  text: 'Work',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.router.push(SellerWorkRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.eye),
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
                leading: const Icon(Iconsax.message),
                title: const AppText(
                  text: 'Socail Links',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.router.push(const SellerProfileVerificationRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.dollar_square),
                title: const AppText(
                  text: 'Earnings',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const SellerEarningRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.money),
                title: const AppText(
                  text: 'Payment Methods',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const SellerPaymentMethodsRoute());
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
                  context.pushRoute(SellerAvailabilityScheduleRoute());
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
                leading: const Icon(Iconsax.personalcard),
                title: const AppText(
                  text: 'Account',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.router.push(const CustomerPersonalDetailsRoute());
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
              ListTile(
                leading: const Icon(Iconsax.wallet),
                title: const AppText(
                  text: 'Wallet',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const CustomerWalletRoute());
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.heart_tick),
                title: const AppText(
                  text: 'My Favorites',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.pushRoute(const CustomerFavoritesRoute());
                },
              ),
            ],
            ListTile(
              leading: const Icon(Iconsax.message),
              title: const AppText(
                text: 'Chats',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              onTap: () {
                context.pushRoute(ConversationListRoute());
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.message_question),
              title: const AppText(
                text: 'Disputes',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              onTap: () {
                final token = getIt<LocalKeyStorage>().accessToken;
                final supportUrl =
                    Environment().config.apiHost.replaceAll('api', 'disputes');
                context.router.pushWidget(SupportWebViewWidget(
                  authToken: token!,
                  title: 'Disputes',
                  supportUrl: supportUrl,
                ));
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.message_question),
              title: const AppText(
                text: 'Support',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              onTap: () {
                final token = getIt<LocalKeyStorage>().accessToken;
                final supportUrl =
                    Environment().config.apiHost.replaceAll('api', 'support');
                context.router.pushWidget(SupportWebViewWidget(
                  authToken: token!,
                  supportUrl: supportUrl,
                ));
              },
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
                AppHelper.showAppDialog(
                  context,
                  OnConfirmDialog(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 48,
                    ),
                    title: 'Logout',
                    content: 'Are you sure you want to logout?',
                    onConfirmed: (_) {
                      context.read<AppCubit>().onLogout();
                    },
                  ),
                );
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
                BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
                  builder: (context, state) {
                    final profileCompleteness =
                        state.profileDetails.data?.profileCompleteness;

                    if (profileCompleteness == null) return const SizedBox();

                    final isProfileComplete =
                        AppHelper.isStylistProfileComplete(profileCompleteness);
                    if (isProfileComplete) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SellerProfileCompletedCompactView(
                        profileCompleteness: profileCompleteness,
                      ),
                    );
                  },
                ),
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
                      if (state.updateAvailabilityState.isLoading)
                        const SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(),
                        )
                      else
                        AppText(
                            text: state.profileDetails.data?.user
                                        ?.stylistProfile?.isAvailable ??
                                    false
                                ? 'ON'
                                : 'OFF'),
                      SizedBox(
                        height: 35,
                        child: BlocListener<SellerProfileMgtCubit,
                            SellerProfileMgtState>(
                          listenWhen: (previous, current) =>
                              previous.updateAvailabilityState !=
                              current.updateAvailabilityState,
                          listener: (context, state) {
                            if (state.updateAvailabilityState.hasError) {
                              AppHelper.showAppDialog(
                                context,
                                OnFailDialogContent(
                                  subtext: (state.updateAvailabilityState.error!
                                              as RemoteException)
                                          .errorResponse
                                          ?.message ??
                                      '',
                                  onDoneCallback: (_) {},
                                ),
                              );
                            }

                            if (state.updateAvailabilityState.hasSuccess) {
                              AppHelper.showSnackBar(
                                context,
                                message: 'Available status updated..',
                              );
                            }
                          },
                          child: Switch(
                            value: state.profileDetails.data?.user
                                    ?.stylistProfile?.isAvailable ??
                                false,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              // if (state.profileDetails.data?.profileCompleteness
                              //         ?.statusApproved ??
                              //     false) {
                              context
                                  .read<SellerProfileMgtCubit>()
                                  .updateAvailability(isAvailable: value);
                              // } else {
                              //   AppHelper.showSnackBar(
                              //     context,
                              //     message:
                              //         'You need to have an active stylist profile to change your availability.',
                              //   );
                              // }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerProfileHeader(BuildContext context) {
    return BlocBuilder<CustomerProfileMgtCubit, CustomerProfileMgtState>(
      builder: (context, state) {
        if (state.profileDetails.data == null) return const SizedBox();
        return GestureDetector(
          onTap: () => context.pushRoute(const CustomerPersonalDetailsRoute()),
          child: Container(
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
                  backgroundImage:
                      state.profileDetails.data?.user?.avatar != null
                          ? CachedNetworkImageProvider(
                              state.profileDetails.data!.user!.avatar
                                  .completeImagePath(),
                            )
                          : null,
                  child: AppText(
                    text: state.profileDetails.data!.user!.name!
                            .split(' ')
                            .first[0]
                            .toUpperCase() +
                        state.profileDetails.data!.user!.name!
                            .split(' ')
                            .last[0]
                            .toUpperCase(),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                10.verticalSpace,
                AppText(
                  text: state.profileDetails.data?.user?.name ?? 'N/A',
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                AppText(
                  text: state.profileDetails.data?.user?.email ?? 'N/A',
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
