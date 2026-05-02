import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:auto_route/annotations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/features/explore/widgets/popular_styles_card.dart';
import 'package:snip_fair/features/explore/widgets/default_stylist_card.dart';
import 'package:snip_fair/features/favorites/cubit/customer_favorites_cubit.dart';

@RoutePage()
class CustomerFavoritesScreen extends StatelessWidget implements AutoRouteWrapper {
  const CustomerFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const Tab(text: 'Stylists'),
      const Tab(text: 'Services'),
      // You can add more tabs here in the future
    ];
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide.none,
              foregroundColor: AppColors.primaryGrey,
              fixedSize: const Size(46, 46),
              alignment: Alignment.center,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.black,
            ),
          ),
          title: AppText(
            text: 'Favorites',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
          centerTitle: true,
          bottom: TabBar(
            tabs: tabs,
            indicatorColor: AppColors.primaryColor,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.grey2,
          ),
        ),
        body: TabBarView(
          children: [
            BlocBuilder<CustomerFavoritesCubit, CustomerFavoritesState>(
              builder: (context, state) {
                if (state.fetchFavoriteStylistsState.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                final stylists = state.fetchFavoriteStylistsState.data?.data ?? [];
                if (stylists.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AppText(
                        text: 'No Favorites found',
                        fontSize: 16,
                        color: AppColors.grey3,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<CustomerFavoritesCubit>().getFavouriteSellers(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    itemBuilder: (context, index) {
                      final stylist = stylists[index];
                      return DefaultStylistCard(
                        seller: stylist,
                        onLikePressed: () async {
                          return context
                              .read<CustomerFavoritesCubit>()
                              .likeStylist(stylist.id!.toString());
                        },
                      );
                    },
                    separatorBuilder: (context, index) => 12.verticalSpace,
                    itemCount: stylists.length,
                  ),
                );
              },
            ),
            BlocBuilder<CustomerFavoritesCubit, CustomerFavoritesState>(
              builder: (context, state) {
                if (state.fetchFavoritePortfoliosState.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                final portfolios = state.fetchFavoritePortfoliosState.data ?? [];
                if (portfolios.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AppText(
                        text: 'No Favorites found',
                        fontSize: 16,
                        color: AppColors.grey3,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<CustomerFavoritesCubit>().getFavouriteSellers(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    itemBuilder: (context, index) {
                      final portfolio = portfolios[index];
                      return PopularStyleCard(
                        portfolio: portfolio,
                        onLikePressed: () async {
                          return context
                              .read<CustomerFavoritesCubit>()
                              .likeService(portfolio.id!.toString());
                        },
                      );
                    },
                    separatorBuilder: (context, index) => 12.verticalSpace,
                    itemCount: portfolios.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CustomerFavoritesCubit>()
        ..getFavouriteSellers()
        ..getFavoriteServices(),
      child: this,
    );
  }
}
