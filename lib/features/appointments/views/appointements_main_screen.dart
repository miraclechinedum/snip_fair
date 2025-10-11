import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';

@RoutePage()
class AppointementsMainScreen extends StatelessWidget {
  const AppointementsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(),
                    8.horizontalSpace,
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: 'Hair Stylist',
                          fontWeight: FontWeight.w600,
                        ),
                        AppText(
                          text: 'Sarah Johnson',
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(23),
                        color: Colors.green.withValues(alpha: .1),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: const AppText(
                        text: 'Confirmed',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    )
                  ],
                ),
                12.verticalSpace,
                const AppText(
                  text: 'Hair Cut and Dye',
                  fontWeight: FontWeight.w600,
                ),
                Row(
                  children: [
                    const Icon(
                      Iconsax.location,
                      size: 15,
                      color: AppColors.grey3,
                    ),
                    4.horizontalSpace,
                    const AppText(
                      text: '12 mirabi street, festac housing estate',
                      fontSize: 12,
                      color: AppColors.grey3,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Iconsax.calendar,
                      size: 15,
                      color: AppColors.grey3,
                    ),
                    4.horizontalSpace,
                    const AppText(
                      text: '25th Sep. 2025',
                      fontSize: 12,
                      color: AppColors.grey3,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Iconsax.clock,
                      size: 15,
                      color: AppColors.grey3,
                    ),
                    4.horizontalSpace,
                    const AppText(
                      text: '8:30 am',
                      fontSize: 12,
                      color: AppColors.grey3,
                    ),
                  ],
                ),
                12.verticalSpace,
                const AppText(
                  text: 'R45',
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
                12.verticalSpace,
                SizedBox(
                  height: 40,
                  child: CustomButton(
                    title: 'View Details',
                    icon: const Icon(Iconsax.document),
                    onPressed: () {},
                    background: AppColors.grey1,
                    textColor: AppColors.black,
                    gradient: null,
                    isOutline: true,
                  ),
                ),
                8.verticalSpace,
                SizedBox(
                  height: 40,
                  child: CustomButton(
                    title: 'Cancel',
                    onPressed: () {},
                    background: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    gradient: null,
                    isOutline: true,
                  ),
                )
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => 12.verticalSpace,
        itemCount: 10,
      ),
    );
  }
}
