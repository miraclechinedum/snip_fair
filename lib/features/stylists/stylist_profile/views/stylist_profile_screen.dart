import 'package:auto_route/annotations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class StylistProfileScreen extends StatelessWidget {
  const StylistProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = <String>[
      'Services & Pricing',
      'Portfolio & Work Samples',
      'Recent Client Reviews',
    ];

    final tabViews = [
      const ServicesListView(),
      const PortfolioView(),
      const ReviewsView(),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAppBar(context, innerBoxIsScrolled, tabs),
            ];
          },
          body: TabBarView(
            children: List.generate(tabs.length, (index) {
              return SafeArea(
                top: false,
                bottom: false,
                child: Builder(
                  builder: (BuildContext context) {
                    return tabViews[index];
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  SliverOverlapAbsorber _buildAppBar(
    BuildContext context,
    bool innerBoxIsScrolled,
    List<String> tabs,
  ) {
    return SliverOverlapAbsorber(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
      sliver: SliverAppBar(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryColor,
        expandedHeight: 470,
        forceElevated: innerBoxIsScrolled,
        pinned: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: ColoredBox(
            color: Colors.white,
            child: TabBar(
              // These are the widgets to put in each tab in the tab bar.
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.zero,
              tabs: tabs.map((String name) => Tab(text: name)).toList(),
              indicatorColor: AppColors.primaryColor,
              labelColor: AppColors.primaryColor,
              labelStyle:
                  AppTextStyle.body2.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyle.body2,
            ),
          ),
        ),
        flexibleSpace: FlexibleSpaceBar(
          stretchModes: const <StretchMode>[
            StretchMode.zoomBackground,
            StretchMode.blurBackground,
          ],
          background: Stack(
            children: [
              SizedBox.expand(
                child: Container(
                  padding: const EdgeInsets.only(top: 50),
                  height: 30,
                  color: Colors.white,
                ),
              ),
              Container(
                height: 150,
                decoration: const BoxDecoration(
                  gradient: AppColors.appgradient,
                ),
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 30,
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        width: 120,
                        child: CustomButton(
                          onPressed: () {},
                          title: 'More info',
                          gradient: null,
                          background:
                              AppColors.primaryColor.withValues(alpha: .1),
                          textColor: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 60,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      12.verticalSpace,
                      Row(
                        children: [
                          const AppText(
                            text: 'Russel Mathew',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          10.horizontalSpace,
                          Icon(
                            Iconsax.verify5,
                            color: Colors.green.shade500,
                          ),
                        ],
                      ),
                      const AppText(
                        text: 'RuxyStylez',
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                      5.verticalSpace,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(
                            Iconsax.star1,
                            color: Colors.amber,
                            size: 20,
                          ),
                          5.horizontalSpace,
                          const AppText(
                            text: '5',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          5.horizontalSpace,
                          const AppText(
                            text: '(2 Reviews)',
                            fontSize: 12,
                            color: AppColors.grey3,
                          ),
                        ],
                      ),
                      3.verticalSpace,
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
                            fontSize: 10,
                            color: AppColors.grey3,
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.grey.shade200,
                      ),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                children: [
                                  AppText(
                                    text: '1+',
                                    fontSize: 20,
                                    maxLines: 1,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                  AppText(
                                    text: 'Services \nCompleted',
                                    textAlign: TextAlign.center,
                                    fontSize: 10,
                                    color: AppColors.blackShade1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.grey.shade200,
                            ),
                            const Expanded(
                              child: Column(
                                children: [
                                  AppText(
                                    text: '1+ years',
                                    fontSize: 20,
                                    maxLines: 1,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                  AppText(
                                    text: 'Work \nExperience',
                                    textAlign: TextAlign.center,
                                    fontSize: 10,
                                    color: AppColors.blackShade1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.grey.shade200,
                            ),
                            const Expanded(
                              child: Column(
                                children: [
                                  AppText(
                                    text: '3+ hours',
                                    fontSize: 20,
                                    maxLines: 1,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                  AppText(
                                    text: 'Max Response \nTime',
                                    textAlign: TextAlign.center,
                                    fontSize: 10,
                                    color: AppColors.blackShade1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      12.verticalSpace,
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.grey1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  const AppText(
                                    text: 'R124 - R152',
                                    fontSize: 16,
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  const AppText(
                                    text: 'Price range',
                                    fontSize: 12,
                                  ),
                                  5.verticalSpace,
                                  const AppText(
                                    text: 'Next available: Tomorrow 6:45 AM',
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewsView extends StatelessWidget {
  const ReviewsView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('services'),
      slivers: <Widget>[
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
            context,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          sliver: SliverFixedExtentList(
            itemExtent: 100.0,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: AppColors.defaultBoxShadow,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              text: 'Rusell Customer',
                              fontWeight: FontWeight.bold,
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const WidgetSpan(
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 15,
                                    ),
                                  ),
                                  const WidgetSpan(
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 15,
                                    ),
                                  ),
                                  const WidgetSpan(
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 15,
                                    ),
                                  ),
                                  const WidgetSpan(
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 15,
                                    ),
                                  ),
                                  const WidgetSpan(
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 15,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' 1 month ago',
                                    style: AppTextStyle.caption
                                        .copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            5.verticalSpace,
                            AppText(text: 'I love it')
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.grey.shade300)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: const AppText(
                              text: 'Customer',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class PortfolioView extends StatelessWidget {
  const PortfolioView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('portfolio'),
      slivers: <Widget>[
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
            context,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          sliver: SliverGrid(
            delegate: SliverChildListDelegate(
              List.generate(10, (index) {
                return CachedNetworkImage(
                  imageUrl:
                      'https://snipfair.com/storage/works/media/sMFZVSnLU7yrq3qwMjV1oQJeiIbPigJX4QAlgwyy.png',
                  fit: BoxFit.cover,
                );
              }),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
          ),
        ),
      ],
    );
  }
}

class ServicesListView extends StatelessWidget {
  const ServicesListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('services'),
      slivers: <Widget>[
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
            context,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          sliver: SliverFixedExtentList(
            itemExtent: 100.0,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: AppColors.defaultBoxShadow,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              text: 'Makeup by Ruxy',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const AppText(
                              text: 'Smooth and glossy finish',
                              fontSize: 12,
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const WidgetSpan(
                                    child: Icon(
                                      Icons.timelapse,
                                      color: Colors.grey,
                                      size: 15,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' 1 Hour',
                                    style: AppTextStyle.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const AppText(
                            text: 'R124',
                            color: AppColors.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 120,
                            height: 30,
                            child: CustomButton(
                              title: 'Book Now',
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }
}
