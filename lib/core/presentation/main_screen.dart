import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';

@RoutePage()
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [
        ExploreMainRoute(),
        StylistsMainRoute(),
        AppointementsMainRoute(),
        AccountMainRoute(),
      ],
      bottomNavigationBuilder: (context, tabsRouter) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // CustomBarItem(
                  //   label: 'Home',
                  //   iconPath: Assets.images.svg.home.path,
                  //   isActive: tabsRouter.activeIndex == 0,
                  //   onTap: () => tabsRouter.setActiveIndex(0),
                  // ),
                  // CustomBarItem(
                  //   label: 'Chat',
                  //   iconPath: Assets.images.svg.messageMultiple.path,
                  //   isActive: tabsRouter.activeIndex == 1,
                  //   onTap: () => tabsRouter.setActiveIndex(1),
                  // ),
                  // CustomBarItem(
                  //   label: 'AI Kare',
                  //   iconPath: Assets.images.svg.sparkles.path,
                  //   isActive: false,
                  //   onTap: () => context.pushRoute(const AiKareTabRoute()),
                  // ),
                  // CustomBarItem(
                  //   label: 'Navi',
                  //   iconPath: Assets.images.svg.navigation.path,
                  //   isActive: tabsRouter.activeIndex == 2,
                  //   onTap: () => tabsRouter.setActiveIndex(2),
                  // ),
                  // CustomBarItem(
                  //   label: 'Menu',
                  //   iconPath: Assets.images.svg.dashboardSquare.path,
                  //   isActive: tabsRouter.activeIndex == 3,
                  //   onTap: () => tabsRouter.setActiveIndex(3),
                  // ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomBarItem extends StatelessWidget {
  const CustomBarItem({
    required this.label,
    required this.iconPath,
    required this.isActive,
    super.key,
    this.onTap,
  });

  final void Function()? onTap;
  final String label;
  final String iconPath;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kThemeAnimationDuration,
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkGrey100 : null,
          borderRadius: BorderRadius.circular(16).r,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              colorFilter: ColorFilter.mode(
                isActive ? AppColors.primaryColor : AppColors.darkGrey700,
                BlendMode.srcIn,
              ),
            ),
            6.verticalSpace,
            AppText(
              text: label,
              fontSize: 12,
              color: isActive ? AppColors.primaryColor : AppColors.darkGrey700,
            )
          ],
        ),
      ),
    );
  }
}
