import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/domain/entities/apointment/customer.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile_details.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';

@RoutePage()
class CustomerProfileMgtScreen extends StatelessWidget {
  const CustomerProfileMgtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(context, innerBoxIsScrolled),
          ];
        },
        body: SafeArea(
          top: false,
          bottom: false,
          child: Builder(
            builder: (context) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CustomerProfileMgtCubit>()
                    ..getProfileDetails()
                    ..getStats();
                },
                child: CustomScrollView(
                  key: const PageStorageKey<String>('services'),
                  slivers: <Widget>[
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            BlocBuilder<CustomerProfileMgtCubit,
                                CustomerProfileMgtState>(
                              builder: (context, state) {
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.grey1),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        text: 'Total Spent',
                                        color: Colors.grey.shade600,
                                      ),
                                      8.verticalSpace,
                                      AppText(
                                        text: state.customerStats.isLoading
                                            ? '...'
                                            : state.customerStats.hasSuccess
                                                ? '${state.customerStats.data!.totalSpendings?.formatAmount()}'
                                                : '!0',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            12.verticalSpace,
                            BlocBuilder<CustomerProfileMgtCubit,
                                CustomerProfileMgtState>(
                              builder: (context, state) {
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.grey1),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        text: 'All Appointments',
                                        color: Colors.grey.shade600,
                                      ),
                                      8.verticalSpace,
                                      AppText(
                                        text: state.customerStats.isLoading
                                            ? '...'
                                            : state.customerStats.hasSuccess
                                                ? '${state.customerStats.data!.totalAppointments}'
                                                : '0',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            12.verticalSpace,
                            BlocBuilder<CustomerProfileMgtCubit,
                                CustomerProfileMgtState>(
                              builder: (context, state) {
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.grey1),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        text: 'Completed',
                                        color: Colors.grey.shade600,
                                      ),
                                      8.verticalSpace,
                                      AppText(
                                        text: state.customerStats.isLoading
                                            ? '...'
                                            : state.customerStats.hasSuccess
                                                ? '${state.customerStats.data!.completedAppointments}'
                                                : '0',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            12.verticalSpace,
                            BlocBuilder<CustomerProfileMgtCubit,
                                CustomerProfileMgtState>(
                              builder: (context, state) {
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.grey1),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        text: 'Failed',
                                        color: Colors.grey.shade600,
                                      ),
                                      8.verticalSpace,
                                      AppText(
                                        text: state.customerStats.isLoading
                                            ? '...'
                                            : state.customerStats.hasSuccess
                                                ? '${state.customerStats.data!.failedAppointments}'
                                                : '0',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            12.verticalSpace,
                            BlocBuilder<CustomerProfileMgtCubit,
                                CustomerProfileMgtState>(
                              builder: (context, state) {
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.grey1),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const AppText(
                                        text: 'Contact Information',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      12.verticalSpace,
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.mail,
                                            size: 15,
                                            color: AppColors.grey3,
                                          ),
                                          4.horizontalSpace,
                                          Expanded(
                                            child: AppText(
                                              text:
                                                  '${state.profileDetails.data?.user?.email}',
                                              color: AppColors.grey3,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      5.verticalSpace,
                                      Row(
                                        children: [
                                          const Icon(
                                            Iconsax.call,
                                            size: 15,
                                            color: AppColors.grey3,
                                          ),
                                          4.horizontalSpace,
                                          AppText(
                                            text: state.profileDetails.data
                                                    ?.user?.phone ??
                                                '',
                                            color: AppColors.grey3,
                                          ),
                                        ],
                                      ),
                                      5.verticalSpace,
                                      Row(
                                        children: [
                                          const Icon(
                                            Iconsax.location,
                                            size: 15,
                                            color: AppColors.grey3,
                                          ),
                                          4.horizontalSpace,
                                          Expanded(
                                            child: AppText(
                                              text: state.profileDetails.data
                                                      ?.user?.country ??
                                                  '',
                                              color: AppColors.grey3,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      12.verticalSpace,
                                      const AppText(
                                        text: 'About Me',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      12.verticalSpace,
                                      AppText(
                                        text: state.profileDetails.data?.user
                                                ?.bio ??
                                            '',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            24.verticalSpace,
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
                                  const AppText(
                                    text: 'Delete Account',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  8.verticalSpace,
                                  const AppText(
                                    text:
                                        '''Once your account is deleted, all of its resources and data will be permanently deleted. Before deleting your account, please download any data or information that you wish to retain. ''',
                                    color: AppColors.grey3,
                                  ),
                                  12.verticalSpace,
                                  BlocListener<CustomerProfileMgtCubit,
                                      CustomerProfileMgtState>(
                                    listenWhen: (previous, current) =>
                                        previous.deleteAccountState !=
                                        current.deleteAccountState,
                                    listener: (context, state) {
                                      if (state.deleteAccountState.hasSuccess) {
                                        Fluttertoast.showToast(
                                          msg: 'Account deleted successfully',
                                        );
                                        // Navigate to initial route or login screen
                                        context.read<AppCubit>().onLogout();
                                      }
                                    },
                                    child: TextButton(
                                      onPressed: () {
                                        AppHelper.showAppDialog(
                                          context,
                                          OnConfirmDialog(
                                            title: 'Delete Account',
                                            content:
                                                'Are you sure you want to delete your account? This action cannot be undone.',
                                            onConfirmed: (ctx) {
                                              context
                                                  .read<
                                                      CustomerProfileMgtCubit>()
                                                  .deleteAccount();
                                            },
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        textStyle: AppTextStyle.body2.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('DELETE ACCOUNT'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  SliverOverlapAbsorber _buildAppBar(
    BuildContext context,
    bool innerBoxIsScrolled,
  ) {
    return SliverOverlapAbsorber(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
      sliver: SliverAppBar(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryColor,
        expandedHeight: 260.h,
        forceElevated: innerBoxIsScrolled,
        pinned: true,
        title: innerBoxIsScrolled
            ? const AppText(
                text: 'Profile Management',
                color: AppColors.white,
              )
            : null,
        centerTitle: false,
        flexibleSpace: FlexibleSpaceBar(
          stretchModes: const <StretchMode>[
            StretchMode.zoomBackground,
            StretchMode.blurBackground,
          ],
          background:
              BlocBuilder<CustomerProfileMgtCubit, CustomerProfileMgtState>(
            builder: (context, state) {
              return Stack(
                children: [
                  SizedBox.expand(
                    child: Container(
                      padding: const EdgeInsets.only(top: 50),
                      height: 30.h,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    height: 150.h,
                    decoration: const BoxDecoration(
                      gradient: AppColors.appgradient,
                    ),
                  ),
                  Container(
                    height: 190.h,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context
                                  .read<CustomerProfileMgtCubit>()
                                  .pickAndUploadAvatar();
                            },
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 5,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SellerProfileAvatar(
                                    profileDetails: state.profileDetails.data,
                                    isLoading:
                                        state.updateAvatarState.isLoading,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      context
                                          .read<CustomerProfileMgtCubit>()
                                          .pickAndUploadAvatar();
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: AppColors.contentColorBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Iconsax.edit,
                                        size: 15,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30.h,
                            width: 150.w,
                            child: CustomButton(
                              onPressed: () {
                                context.router
                                    .push(const CustomerPersonalDetailsRoute());
                              },
                              title: 'Edit Profile',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.profileDetails.isLoading)
                    const LinearProgressIndicator()
                  else
                    Container(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ).r,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            12.verticalSpace,
                            Row(
                              children: [
                                AppText(
                                  text: state.profileDetails.data?.user?.name ??
                                      '',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                10.horizontalSpace,
                                // ignore: use_if_null_to_convert_nulls_to_bools
                                if (state.profileDetails.data?.user?.status ==
                                    'verified')
                                  Icon(
                                    Iconsax.verify5,
                                    color: Colors.green.shade500,
                                  ),
                              ],
                            ),
                            const AppText(
                              text: 'Customer',
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                            5.verticalSpace,
                            AppText(
                              text:
                                  '${state.customerStats.data?.totalAppointments ?? 0} Appointments',
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SellerProfileAvatar extends StatelessWidget {
  const SellerProfileAvatar({
    super.key,
    required this.profileDetails,
    this.radius = 30,
    this.isLoading = false,
  });

  final CustomerProfileDetails? profileDetails;
  final double radius;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: profileDetails?.user?.avatar != null
          ? CachedNetworkImageProvider(
              profileDetails!.user!.avatar!.completeImagePath(),
            )
          : null,
      child: isLoading
          ? const CircularProgressIndicator()
          : profileDetails?.user?.avatar != null
              ? null
              : AppText(
                  text: profileDetails?.user?.firstName != null &&
                          profileDetails?.user?.lastName != null
                      ? AppHelper.initialsFromName(
                          profileDetails!.user!.firstName!,
                          profileDetails!.user!.lastName!,
                        )
                      : 'N/A',
                  color: AppColors.grey3,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
    );
  }
}
