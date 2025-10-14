import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/profile_completeness.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_item.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/seller/shared/profile_completeness_compact_view.dart';

@RoutePage()
class SellerProfileManagementScreen extends StatelessWidget {
  const SellerProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SellerProfileMgtCubit, SellerProfileMgtState>(
          listenWhen: (previous, current) =>
              previous.updateAvatarState != current.updateAvatarState,
          listener: (context, state) {
            if (state.updateAvatarState.hasError) {
              AppHelper.showAppDialog<void>(
                context,
                OnFailDialogContent(
                  subtext: state.updateAvatarState.error!.toString(),
                  onDoneCallback: (_) {},
                ),
              );
            }
          },
        ),
        BlocListener<SellerProfileMgtCubit, SellerProfileMgtState>(
          listenWhen: (previous, current) =>
              previous.updateBannerState != current.updateBannerState,
          listener: (context, state) {
            if (state.updateBannerState.hasError) {
              AppHelper.showAppDialog<void>(
                context,
                OnFailDialogContent(
                  subtext: state.updateBannerState.error!.toString(),
                  onDoneCallback: (_) {},
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
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
                    context.read<SellerProfileMgtCubit>()
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
                              BlocBuilder<SellerProfileMgtCubit,
                                  SellerProfileMgtState>(
                                builder: (context, state) {
                                  final profileCompleteness = state
                                      .profileDetails.data?.profileCompleteness;
                                  if (profileCompleteness == null) {
                                    return const SizedBox();
                                  }
                                  final isProfileComplete =
                                      AppHelper.isStylistProfileComplete(
                                    profileCompleteness,
                                  );
                                  if (isProfileComplete) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SellerProfileCompletedCompactView(
                                      profileCompleteness: profileCompleteness,
                                    ),
                                  );
                                },
                              ),
                              BlocBuilder<SellerProfileMgtCubit,
                                  SellerProfileMgtState>(
                                builder: (context, state) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(8).r,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.grey200,
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.05),
                                        borderRadius:
                                            BorderRadius.circular(8).r,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              text: state.profileDetails.data
                                                      ?.profileLink ??
                                                  '',
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (state.profileDetails.data
                                                      ?.profileLink !=
                                                  null) {
                                                AppHelper.copyToClipboard(
                                                  context,
                                                  state.profileDetails.data!
                                                      .profileLink!,
                                                );
                                              }
                                            },
                                            child: const Icon(
                                              Iconsax.copy,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              24.verticalSpace,
                              BlocBuilder<SellerProfileMgtCubit,
                                  SellerProfileMgtState>(
                                builder: (context, state) {
                                  return Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                      border:
                                          Border.all(color: AppColors.grey1),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const AppText(
                                              text: 'Services & Pricing',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(
                                                Iconsax.edit_24,
                                                size: 15,
                                              ),
                                              onPressed: () {
                                                context.pushRoute(
                                                  SellerWorkRoute(),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    8,
                                                  ),
                                                ),
                                                textStyle: AppTextStyle.caption
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                foregroundColor:
                                                    AppColors.black,
                                                backgroundColor:
                                                    const Color(0xffF6F7F8),
                                              ),
                                              label: const Text('Manage All'),
                                            ),
                                          ],
                                        ),
                                        const Divider(),
                                        if (state.profileDetails.data
                                                ?.portfolios !=
                                            null)
                                          SizedBox(
                                            height: 100,
                                            child: ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              itemBuilder: (context, index) {
                                                final portfolio = state
                                                    .profileDetails
                                                    .data!
                                                    .portfolios![index];
                                                return Container(
                                                  width: 200,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(8)
                                                            .r,
                                                    border: Border.all(
                                                      color: AppColors.grey300,
                                                    ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: AppText(
                                                              text: portfolio
                                                                      .title ??
                                                                  'N/A',
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
                                                              context.router
                                                                  .push(
                                                                SellerWorkRoute(
                                                                  workItem: WorkItem
                                                                      .fromPortfolio(
                                                                    portfolio,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: const Icon(
                                                              Iconsax.edit_2,
                                                              color:
                                                                  Colors.blue,
                                                              size: 15,
                                                            ),
                                                          ),
                                                          // 10.horizontalSpace,
                                                          // Icon(
                                                          //   Iconsax.trash,
                                                          //   color: Colors.red,
                                                          //   size: 15,
                                                          // ),
                                                        ],
                                                      ),
                                                      const Spacer(),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: FittedBox(
                                                              child: AppText(
                                                                text: portfolio
                                                                    .price!
                                                                    .formatAmount(),
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                          20.horizontalSpace,
                                                          const Icon(
                                                            Icons
                                                                .access_time_outlined,
                                                            size: 15,
                                                          ),
                                                          5.horizontalSpace,
                                                          AppText(
                                                            text:
                                                                '${portfolio.duration}',
                                                            fontSize: 10,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              separatorBuilder:
                                                  (context, index) =>
                                                      12.horizontalSpace,
                                              itemCount: state
                                                      .profileDetails
                                                      .data!
                                                      .portfolios
                                                      ?.length ??
                                                  0,
                                            ),
                                          )
                                        else
                                          const AppText(text: 'No Services'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              24.verticalSpace,
                              BlocBuilder<SellerProfileMgtCubit,
                                  SellerProfileMgtState>(
                                builder: (context, state) {
                                  return Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                      border:
                                          Border.all(color: AppColors.grey1),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                    TextButton(
                                      onPressed: () {},
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
        expandedHeight: 310,
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
          background: BlocBuilder<SellerProfileMgtCubit, SellerProfileMgtState>(
            builder: (context, state) {
              return Stack(
                children: [
                  SizedBox.expand(
                    child: Container(
                      padding: const EdgeInsets.only(top: 50),
                      height: 30,
                      color: Colors.white,
                    ),
                  ),
                  Stack(
                    children: [
                      Container(
                        height: 150,
                        decoration: const BoxDecoration(
                          gradient: AppColors.appgradient,
                        ),
                        child: state.updateBannerState.isLoading
                            ? const LinearProgressIndicator()
                            : state.profileDetails.data?.user?.stylistProfile
                                        ?.banner !=
                                    null
                                ? CachedNetworkImage(
                                    imageUrl: state.profileDetails.data?.user
                                            ?.stylistProfile?.banner
                                            ?.completeImagePath() ??
                                        '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 150,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            context
                                .read<SellerProfileMgtCubit>()
                                .pickAndUploadBanner();
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
                  Container(
                    height: 190,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Stack(
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
                                  isLoading: state.updateAvatarState.isLoading,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    context
                                        .read<SellerProfileMgtCubit>()
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
                          SizedBox(
                            height: 30,
                            width: 150,
                            child: CustomButton(
                              onPressed: () {
                                context.router
                                    .push(const SellerPersonalDetailsRoute());
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
                        ),
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
                                if (state.profileDetails.data?.user
                                        ?.stylistProfile?.status ==
                                    'verified')
                                  Icon(
                                    Iconsax.verify5,
                                    color: Colors.green.shade500,
                                  ),
                              ],
                            ),
                            AppText(
                              text: state.profileDetails.data?.user
                                      ?.stylistProfile?.businessName ??
                                  'N/A',
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                            5.verticalSpace,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
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
                            5.verticalSpace,
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.calendar,
                                  size: 15,
                                  color: AppColors.grey3,
                                ),
                                4.horizontalSpace,
                                AppText(
                                  text:
                                      '${state.profileDetails.data?.user?.stylistProfile?.yearsOfExperience} Years of experience',
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
                                AppText(
                                  text: state
                                          .profileDetails.data?.user?.country ??
                                      '',
                                  color: AppColors.grey3,
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
                                  text:
                                      state.profileDetails.data?.user?.phone ??
                                          '',
                                  color: AppColors.grey3,
                                ),
                              ],
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

  final StylistProfileDetails? profileDetails;
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
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
    );
  }
}
