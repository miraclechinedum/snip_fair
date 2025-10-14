// ignore_for_file: unawaited_futures

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/features/explore/cubit/explore_cubit.dart';
import 'package:snip_fair/features/explore/widgets/default_stylist_card.dart';
import 'package:snip_fair/features/explore/widgets/popular_styles_card.dart';
import 'package:snip_fair/features/explore/widgets/top_stylist_card.dart';
import 'package:snip_fair/gen/assets.gen.dart';

@RoutePage()
class ExploreMainScreen extends StatelessWidget implements AutoRouteWrapper {
  const ExploreMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white10,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ExploreCubit>()
            ..getTrendingServices()
            ..getTopRatedSellers()
            ..getMostPopularSellers()
            ..getCheapSellers()
            ..getNearbySellers();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              //Search Bar
              12.verticalSpace,
              GestureDetector(
                onTap: () {
                  AutoTabsRouter.of(context).setActiveIndex(1);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.grey1,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Iconsax.search_normal),
                      10.horizontalSpace,
                      const AppText(text: 'Search for stylists'),
                    ],
                  ),
                ),
              ),
              24.verticalSpace,
              //Most popular
              BlocBuilder<ExploreCubit, ExploreState>(
                buildWhen: (previous, current) =>
                    previous.trendingServices != current.trendingServices,
                builder: (context, state) {
                  return buildMostPopularStyles(
                    label: 'Trending styles',
                    portfolios: state.trendingServices.data ?? [],
                    isLoading: state.trendingServices.isLoading,
                  );
                },
              ),
              20.verticalSpace,
              //Top rated
              BlocBuilder<ExploreCubit, ExploreState>(
                buildWhen: (previous, current) =>
                    previous.topRated != current.topRated,
                builder: (context, state) {
                  return buildHorizontalStylists(
                    label: 'Top rated',
                    sellers: state.topRated.data?.data ?? [],
                    isLoading: state.topRated.isLoading,
                  );
                },
              ),
              12.verticalSpace,
              BlocBuilder<ExploreCubit, ExploreState>(
                buildWhen: (previous, current) =>
                    previous.nearByStylists != current.nearByStylists,
                builder: (context, state) {
                  return buildVerticalStylists(
                    label: 'NearBy',
                    sellers: state.nearByStylists.data?.data ?? [],
                    isLoading: state.nearByStylists.isLoading,
                  );
                },
              ),
              12.verticalSpace,
              BlocBuilder<ExploreCubit, ExploreState>(
                buildWhen: (previous, current) =>
                    previous.mostPopular != current.mostPopular,
                builder: (context, state) {
                  return buildHorizontalStylists(
                    label: 'Most popular',
                    sellers: state.mostPopular.data?.data ?? [],
                    isLoading: state.mostPopular.isLoading,
                  );
                },
              ),
              12.verticalSpace,
              BlocBuilder<ExploreCubit, ExploreState>(
                buildWhen: (previous, current) =>
                    previous.experiencedStylists != current.experiencedStylists,
                builder: (context, state) {
                  return buildVerticalStylists(
                    label: 'Experienced Stylists',
                    sellers: state.experiencedStylists.data?.data ?? [],
                    isLoading: state.experiencedStylists.isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildVerticalStylists({
    required String label,
    required List<SellerDetails> sellers,
    required bool isLoading,
  }) {
    if (sellers.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppText(
            text: label,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        8.verticalSpace,
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final seller = sellers[index];
            return DefaultStylistCard(
              seller: seller,
              onLikePressed: () {
                return context
                    .read<ExploreCubit>()
                    .likeStylist(seller.stylistProfile!.id!.toString());
              },
            );
          },
          separatorBuilder: (context, index) => 12.verticalSpace,
          itemCount: sellers.length,
        ),
      ],
    );
  }

  Widget buildHorizontalStylists({
    required String label,
    required List<SellerDetails> sellers,
    required bool isLoading,
  }) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: 150,
                height: 18,
                color: Colors.white, // This will be the "shimmered" area
              ),
            ),
          ),
          8.verticalSpace,
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 150,
                              color: Colors
                                  .white, // This will be the "shimmered" area
                            ),
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xffF9F6F5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                child: Container(
                                  width: 150,
                                  height: 12,
                                  color: Colors
                                      .white, // This will be the "shimmered" area
                                ),
                              ),
                            ),
                          ],
                        ),
                        8.verticalSpace,
                        Row(
                          children: [
                            8.horizontalSpace,
                            Container(
                              width: 50,
                              height: 15,
                              color: Colors
                                  .white, // This will be the "shimmered" area
                            ),
                            const Spacer(),
                            Container(
                              width: 120,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              // This will be the "shimmered" area
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => 12.horizontalSpace,
              itemCount: 5,
            ),
          ),
        ],
      );
    }
    if (sellers.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (label == 'Top rated') ...[
                SvgPicture.asset(
                  Assets.images.crown,
                  colorFilter: const ColorFilter.mode(
                    Color(0xffE8AF09),
                    BlendMode.srcIn,
                  ),
                ),
                8.horizontalSpace,
              ],
              AppText(
                text: label,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              12.horizontalSpace,
              if (label == 'Top rated')
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
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final seller = sellers[index];
              return TopStylistCard(
                seller: seller,
                onLikePressed: () {
                  return context
                      .read<ExploreCubit>()
                      .likeStylist(seller.stylistProfile!.id!.toString());
                },
              );
            },
            separatorBuilder: (context, index) => 12.horizontalSpace,
            itemCount: sellers.length,
          ),
        ),
      ],
    );
  }

  Widget buildMostPopularStyles({
    required String label,
    required List<SellerPortfolio> portfolios,
    required bool isLoading,
  }) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: 150,
                height: 18,
                color: Colors.white, // This will be the "shimmered" area
              ),
            ),
          ),
          8.verticalSpace,
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 150,
                              color: Colors
                                  .white, // This will be the "shimmered" area
                            ),
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xffF9F6F5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                child: Container(
                                  width: 150,
                                  height: 12,
                                  color: Colors
                                      .white, // This will be the "shimmered" area
                                ),
                              ),
                            ),
                          ],
                        ),
                        8.verticalSpace,
                        Row(
                          children: [
                            8.horizontalSpace,
                            Container(
                              width: 50,
                              height: 15,
                              color: Colors
                                  .white, // This will be the "shimmered" area
                            ),
                            const Spacer(),
                            Container(
                              width: 120,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              // This will be the "shimmered" area
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => 12.horizontalSpace,
              itemCount: 5,
            ),
          ),
        ],
      );
    }

    if (portfolios.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AppText(
                text: label,
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
              final portfolio = portfolios[index];
              return PopularStyleCard(
                portfolio: portfolio,
              );
            },
            separatorBuilder: (context, index) => 12.horizontalSpace,
            itemCount: portfolios.length,
          ),
        ),
      ],
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ExploreCubit>()
        ..getTrendingServices()
        ..getTopRatedSellers()
        ..getMostPopularSellers()
        ..getCheapSellers()
        ..getNearbySellers(),
      child: this,
    );
  }
}
