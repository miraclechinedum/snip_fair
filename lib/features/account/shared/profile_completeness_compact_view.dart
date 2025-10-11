import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import 'package:snip_fair/core/domain/entities/stylist_profile_details/profile_completeness.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/utils.dart';

class SellerProfileCompletedCompactView extends StatelessWidget {
  const SellerProfileCompletedCompactView({
    required this.profileCompleteness,
    super.key,
  });

  final ProfileCompleteness profileCompleteness;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHelper.showCustomModalBottomSheet<void>(
          context: context,
          modal: SellerProfileCompletenessFullView(
            profileCompleteness: profileCompleteness,
          ),
          isDarkMode: false,
        );
      },
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppText(
                  text: 'Profile Completeness',
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                const Spacer(),
                AppText(
                  text:
                      '${AppHelper.profilePercentCompletion(profileCompleteness).toStringAsFixed(0)}%',
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ],
            ),
            12.verticalSpace,
            LinearProgressIndicator(
              value:
                  AppHelper.profilePercentCompletion(profileCompleteness) / 100,
              backgroundColor: AppColors.grey300,
              borderRadius: BorderRadius.circular(4).r,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor,
              ),
              minHeight: 8.h,
            ),
            5.verticalSpace,
            const AppText(
              text: 'Click to view more details',
              fontSize: 12,
              color: AppColors.primaryColor,
            )
          ],
        ),
      ),
    );
  }
}

class SellerProfileCompletenessFullView extends StatelessWidget {
  const SellerProfileCompletenessFullView({
    required this.profileCompleteness,
    Key? key,
  }) : super(key: key);

  final ProfileCompleteness profileCompleteness;

  @override
  Widget build(BuildContext context) {
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
                  children: [
                    Row(
                      children: [
                        const AppText(
                          text: 'Profile Completeness',
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        const Spacer(),
                        AppText(
                          text:
                              '${AppHelper.profilePercentCompletion(profileCompleteness).toStringAsFixed(0)}%',
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ],
                    ),
                    12.verticalSpace,
                    LinearProgressIndicator(
                      value: AppHelper.profilePercentCompletion(
                              profileCompleteness) /
                          100,
                      backgroundColor: AppColors.grey300,
                      borderRadius: BorderRadius.circular(4).r,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                      minHeight: 8.h,
                    ),
                    24.verticalSpace,
                    _buildProfileStep(
                      label: 'Complete bio',
                      completed: profileCompleteness.userBio ?? false,
                      onTap: () {
                        Navigator.pop(context);

                        context.router.push(const PersonalDetailsRoute());
                      },
                    ),
                    _buildProfileStep(
                      label: 'Specify current address',
                      completed: profileCompleteness.address ?? false,
                      onTap: () {
                        Navigator.pop(context);

                        context.router.push(const PersonalDetailsRoute());
                      },
                    ),
                    _buildProfileStep(
                      label: 'Set location service',
                      completed: profileCompleteness.locationService != null,
                      onTap: () {},
                    ),
                    _buildProfileStep(
                      label: 'Upload profile photo',
                      completed: profileCompleteness.userAvatar ?? false,
                      onTap: () {
                        Navigator.pop(context);

                        context.router
                            .push(const SellerProfileManagementRoute());
                      },
                    ),
                    _buildProfileStep(
                      label: 'Upload profile banner',
                      completed: profileCompleteness.userBanner ?? false,
                      onTap: () {
                        Navigator.pop(context);

                        context.router
                            .push(const SellerProfileManagementRoute());
                      },
                    ),
                    _buildProfileStep(
                      label: 'Add social media links',
                      completed: profileCompleteness.socialLinks ?? false,
                      onTap: () {
                        Navigator.pop(context);
                        if (context.router.current.name ==
                            SellerProfileVerificationRoute.name) {
                          return;
                        }
                        context.router
                            .push(const SellerProfileVerificationRoute());
                      },
                    ),
                    _buildProfileStep(
                      label: 'Upload past works',
                      completed: profileCompleteness.works ?? false,
                      onTap: () {
                        Navigator.pop(context);

                        context.router
                            .push(const SellerProfileVerificationRoute());
                      },
                    ),
                    _buildProfileStep(
                      label: 'Add portfolio items',
                      completed: profileCompleteness.portfolio ?? false,
                      onTap: () {
                        Navigator.pop(context);

                        context.router.push(SellerWorkRoute());
                      },
                    ),
                    _buildProfileStep(
                      label: 'Active Payout method',
                      completed: profileCompleteness.paymentMethod ?? false,
                      onTap: () {
                        Navigator.pop(context);

                        context.router.push(const SellerPaymentMethodsRoute());
                      },
                    ),
                    _buildProfileStep(
                      label: 'Business Profile approval',
                      completed: profileCompleteness.statusApproved ?? false,
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey200,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              title: 'Complete verification',
              onPressed: () {
                Navigator.pop(context);
                final router = AutoRouter.of(context);
                if (router.current.name ==
                    SellerProfileVerificationRoute.name) {
                  return;
                }
                context.router.push(
                  const SellerProfileVerificationRoute(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep({
    required String label,
    required bool completed,
    void Function()? onTap,
  }) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: completed ? AppColors.success.withOpacity(0.1) : null,
          shape: BoxShape.circle,
        ),
        child: completed
            ? const Icon(
                Iconsax.tick_circle,
                color: AppColors.success,
              )
            : const Icon(
                Iconsax.activity,
                color: AppColors.grey400,
              ),
      ),
      title: AppText(
        text: label,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      trailing: onTap != null ? const Icon(Iconsax.arrow_right_3) : null,
      onTap: onTap,
    );
  }
}
