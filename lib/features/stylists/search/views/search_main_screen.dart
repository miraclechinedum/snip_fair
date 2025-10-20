import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/features/explore/widgets/default_stylist_card.dart';
import 'package:snip_fair/features/explore/widgets/popular_styles_card.dart';
import 'package:snip_fair/features/stylists/search/cubit/search_cubit.dart';

@RoutePage()
class SearchMainScreen extends StatelessWidget implements AutoRouteWrapper {
  const SearchMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          16.verticalSpace,
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: AppColors.grey1),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    context.read<SearchCubit>().search(value);
                  },
                  decoration: AppColors.inputDecoration.copyWith(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.grey2,
                    ),
                    hintText: 'Search for stylists or services',
                    hintStyle: AppTextStyle.body2.copyWith(
                      color: AppColors.grey2,
                    ),
                  ),
                ),
                10.verticalSpace,
                SizedBox(
                  height: 40,
                  child: BlocBuilder<SearchCubit, SearchState>(
                    buildWhen: (previous, current) =>
                        previous.categories != current.categories ||
                        previous.selectedCategory != current.selectedCategory,
                    builder: (context, state) {
                      if (state.categories.isLoading) {
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 100,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors
                                    .white, // This will be the "shimmered" area
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          separatorBuilder: (_, __) => 10.horizontalSpace,
                          itemCount: 12,
                        );
                      }

                      final categories = state.categories.data ?? [];

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        // padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final isSelected = state.selectedCategory?.id ==
                                  categories[index].id ||
                              (state.selectedCategory == null && index == 0);

                          return AnimationButtonEffect(
                            child: GestureDetector(
                              onTap: () {
                                context
                                    .read<SearchCubit>()
                                    .onSelectCategory(categories[index]);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? AppColors.primaryColor
                                          .withValues(alpha: .1)
                                      : null,
                                  border: Border.all(
                                    color: AppColors.grey1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: Center(
                                  child: AppText(
                                    text: categories[index].name ?? '',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => 10.horizontalSpace,
                        itemCount: categories.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          16.verticalSpace,
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state.stylists.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                final stylists = state.stylists.data?.data ?? [];
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<SearchCubit, SearchState>(
                        buildWhen: (previous, current) =>
                            previous.services != current.services,
                        builder: (context, state) {
                          return buildServices(
                            label: 'Services',
                            portfolios: state.services.data ?? [],
                            isLoading: state.services.isLoading,
                          );
                        },
                      ),
                      12.verticalSpace,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: AppText(
                              text: 'Stylists',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          10.verticalSpace,
                          if (stylists.isNotEmpty)
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                final stylist = stylists[index];
                                return DefaultStylistCard(
                                  seller: stylist,
                                  onLikePressed: () async {
                                    return context
                                        .read<SearchCubit>()
                                        .likeStylist(stylist.id!.toString());
                                  },
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  12.verticalSpace,
                              itemCount: stylists.length,
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: AppText(
                                text: 'No stylists found',
                                fontSize: 16,
                                color: AppColors.grey3,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildServices({
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
                onLikePressed: () {
                  return context
                      .read<SearchCubit>()
                      .likePortfolio(portfolio.id!.toString());
                },
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
      create: (context) => getIt<SearchCubit>()
        ..fetchCategories()
        ..search(''),
      child: this,
    );
  }
}
