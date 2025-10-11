import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/features/explore/widgets/default_stylist_card.dart';
import 'package:snip_fair/features/explore/widgets/popular_styles_card.dart';
import 'package:snip_fair/features/explore/widgets/top_stylist_card.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class ExploreMainScreen extends StatelessWidget {
  const ExploreMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white10,
      body: SingleChildScrollView(
        child: Column(
          children: [
            //Search Bar
            12.verticalSpace,
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.grey1,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Iconsax.search_normal),
                  10.horizontalSpace,
                  const AppText(text: 'Search for stylists')
                ],
              ),
            ),
            24.verticalSpace,
            //Most popular
            buildMostPopularStyles(),
            20.verticalSpace,
            //Top rated
            buildTopRatedStylists(),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const AppText(
                    text: 'Available Stylists',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                8.verticalSpace,
                ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    return const DefaultStylistCard();
                  },
                  separatorBuilder: (context, index) => 12.verticalSpace,
                  itemCount: 10,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Column buildTopRatedStylists() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                Assets.images.crown,
                colorFilter: const ColorFilter.mode(
                  Color(0xffE8AF09),
                  BlendMode.srcIn,
                ),
              ),
              8.horizontalSpace,
              const AppText(
                text: 'Top rated',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              12.horizontalSpace,
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xffE8AC09),
                      Color(0xffF87715),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: const AppText(
                  text: 'Elite Professionals',
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        8.verticalSpace,
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return const TopStylistCard();
            },
            separatorBuilder: (context, index) => 12.horizontalSpace,
            itemCount: 10,
          ),
        ),
      ],
    );
  }

  Column buildMostPopularStyles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AppText(
                text: 'Most Popular',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ],
          ),
        ),
        8.verticalSpace,
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return const PopularStyleCard();
            },
            separatorBuilder: (context, index) => 12.horizontalSpace,
            itemCount: 10,
          ),
        ),
      ],
    );
  }
}
