import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';

import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppCubit>().state;
    return AutoTabsScaffold(
      appBarBuilder: (context, tabsRouter) {
        if (appState.isStylist) {
          if (tabsRouter.activeIndex == 2) {
            return PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(),
            );
          }
        } else {
          if (tabsRouter.activeIndex == 3) {
            return PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(),
            );
          }

          if (tabsRouter.activeIndex == 1) {
            return PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(),
            );
          }
        }

        return AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          title: SvgPicture.asset(
            Assets.images.logoText,
            width: 120,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Iconsax.notification),
            ),
          ]
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: e,
                ),
              )
              .toList(),
        );
      },
      routes: appState.isStylist
          ? const [
              SellerDashboardMainRoute(),
              SellerAppointmentsMainRoute(),
              AccountMainRoute(),
            ]
          : const [
              ExploreMainRoute(),
              SearchMainRoute(),
              AppointementsMainRoute(),
              AccountMainRoute(),
            ],
      bottomNavigationBuilder: (context, tabsRouter) {
        final items = appState.isStylist
            ? [
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.menu_board),
                  label: 'Dashboard',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.calendar),
                  label: 'Appointments',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.setting_44),
                  label: 'Menu',
                ),
              ]
            : [
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.home),
                  label: 'Explore',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.search_normal),
                  label: 'Search',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.calendar),
                  label: 'Appointments',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Iconsax.setting_44),
                  label: 'Menu',
                ),
              ];
        return BottomNavigationBar(
          items: items,
          selectedLabelStyle:
              AppTextStyle.caption.copyWith(fontWeight: FontWeight.w600),
          currentIndex: tabsRouter.activeIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryColor,
          backgroundColor: AppColors.white,
          onTap: (index) => tabsRouter.setActiveIndex(index),
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
            ),
          ],
        ),
      ),
    );
  }
}
