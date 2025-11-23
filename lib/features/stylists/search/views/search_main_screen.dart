import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          context.read<SearchCubit>().search(value);
                        },
                        decoration: AppColors.inputDecoration.copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
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
                    ),
                    10.horizontalSpace,
                    GestureDetector(
                      onTap: () => _showFilterSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.grey1,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                10.verticalSpace,
                SizedBox(
                  height: 40.h,
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
                              width: 100.w,
                              height: 40.h,
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
                                ).r,
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

  void _showFilterSheet(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    final state = context.read<SearchCubit>().state;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FilterSheet(state: state, cubit: cubit);
      },
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
                width: 150.w,
                height: 18.h,
                color: Colors.white, // This will be the "shimmered" area
              ),
            ),
          ),
          8.verticalSpace,
          SizedBox(
            height: 220.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 300.w,
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
                              height: 150.h,
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
          height: 230.h,
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

class FilterSheet extends StatelessWidget {
  const FilterSheet({
    super.key,
    required this.state,
    required this.cubit,
  });

  final SearchState state;
  final SearchCubit cubit;

  @override
  Widget build(BuildContext context) {
    var selectedSort = state.sortOption;
    var selectedRange = state.priceRange;
    var highestRated = state.highestRated;
    var online = state.online;
    var lowestPriceFlag = state.lowestPriceFlag;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          void apply() {
            cubit
              ..setSortOption(selectedSort)
              ..setPriceRange(selectedRange)
              ..toggleHighestRated(highestRated)
              ..toggleOnline(online)
              ..toggleLowestPriceFlag(lowestPriceFlag);

            cubit.search(cubit.state.searchQuery);
            Navigator.of(ctx).pop();
          }

          void clear() {
            selectedSort = SortOption.distance;
            selectedRange = PriceRangeFilter.all;
            highestRated = false;
            online = false;
            lowestPriceFlag = false;
            setModalState(() {});
          }

          Widget radio(SortOption opt, String label) {
            return RadioListTile<SortOption>(
              value: opt,
              title: Text(label),
              activeColor: AppColors.primaryColor,
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Sort & Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                            onPressed: clear, child: const Text('Clear')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Sort by',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    RadioGroup<SortOption>(
                        groupValue: selectedSort,
                        onChanged: (v) {
                          setModalState(() {
                            selectedSort = v!;
                          });
                          print('CHanges $selectedSort');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            radio(SortOption.distance, 'Distance'),
                            radio(SortOption.bookingsCount, 'Bookings count'),
                            radio(SortOption.likesCount, 'Likes count'),
                            radio(SortOption.lowestPrice, 'Lowest price'),
                            radio(SortOption.highestPrice, 'Highest price'),
                          ],
                        )),
                    const SizedBox(height: 12),
                    const Divider(
                      thickness: 0.5,
                    ),
                    const SizedBox(height: 12),
                    const Text('Price range',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Below 50'),
                          selected: selectedRange == PriceRangeFilter.below50,
                          onSelected: (_) {
                            selectedRange = PriceRangeFilter.below50;
                            setModalState(() {});
                          },
                        ),
                        ChoiceChip(
                          label: const Text('50 - 100'),
                          selected:
                              selectedRange == PriceRangeFilter.from50To100,
                          onSelected: (_) {
                            selectedRange = PriceRangeFilter.from50To100;
                            setModalState(() {});
                          },
                        ),
                        ChoiceChip(
                          label: const Text('101 - 150'),
                          selected:
                              selectedRange == PriceRangeFilter.from101To150,
                          onSelected: (_) {
                            selectedRange = PriceRangeFilter.from101To150;
                            setModalState(() {});
                          },
                        ),
                        ChoiceChip(
                          label: const Text('150 - 200'),
                          selected:
                              selectedRange == PriceRangeFilter.from150To200,
                          onSelected: (_) {
                            selectedRange = PriceRangeFilter.from150To200;
                            setModalState(() {});
                          },
                        ),
                        ChoiceChip(
                          label: const Text('200 and above'),
                          selected: selectedRange == PriceRangeFilter.above200,
                          onSelected: (_) {
                            selectedRange = PriceRangeFilter.above200;
                            setModalState(() {});
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Any'),
                          selected: selectedRange == PriceRangeFilter.all,
                          onSelected: (_) {
                            selectedRange = PriceRangeFilter.all;
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      thickness: 0.5,
                    ),
                    const SizedBox(height: 12),
                    const Text('Quick filters',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SwitchListTile(
                      value: highestRated,
                      onChanged: (v) => setModalState(() => highestRated = v),
                      title: const Text('Highest rating'),
                    ),
                    SwitchListTile(
                      value: online,
                      onChanged: (v) => setModalState(() => online = v),
                      title: const Text('Online'),
                    ),
                    SwitchListTile(
                      value: lowestPriceFlag,
                      onChanged: (v) =>
                          setModalState(() => lowestPriceFlag = v),
                      title: const Text('Lowest price'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: apply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
