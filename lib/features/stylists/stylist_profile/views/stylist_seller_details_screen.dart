import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/stylists/stylist_profile/cubit/stylist_seller_details_cubit.dart';

@RoutePage()
class StylistSellerDetailsScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const StylistSellerDetailsScreen({super.key, this.seller, this.id});
  final String? id;
  final SellerDetails? seller;

  @override
  Widget build(BuildContext context) {
    final tabs = <String>[
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
        body: BlocBuilder<StylistSellerDetailsCubit, StylistSellerDetailsState>(
          builder: (context, state) {
            if (state.sellerDetails.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return NestedScrollView(
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
            );
          },
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
              BlocBuilder<StylistSellerDetailsCubit, StylistSellerDetailsState>(
                builder: (context, state) {
                  return Container(
                    height: 150,
                    decoration: const BoxDecoration(
                      gradient: AppColors.appgradient,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: state.sellerDetails.data?.stylistProfile?.banner
                              ?.completeImagePath() ??
                          '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                      errorWidget: (context, url, error) =>
                          const SizedBox.expand(),
                      placeholder: (context, url) =>
                          const LinearProgressIndicator(),
                    ),
                  );
                },
              ),
              BlocBuilder<StylistSellerDetailsCubit, StylistSellerDetailsState>(
                builder: (context, state) {
                  return Container(
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
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  state.sellerDetails.data?.avatar != null
                                      ? CachedNetworkImageProvider(
                                          state.sellerDetails.data!.avatar!
                                              .completeImagePath(),
                                        )
                                      : null,
                              child: state.sellerDetails.data?.avatar != null
                                  ? null
                                  : AppText(
                                      text:
                                          state.sellerDetails.data?.firstName !=
                                                      null &&
                                                  state.sellerDetails.data
                                                          ?.lastName !=
                                                      null
                                              ? AppHelper.initialsFromName(
                                                  state.sellerDetails.data!
                                                      .firstName!,
                                                  state.sellerDetails.data!
                                                      .lastName!,
                                                )
                                              : 'N/A',
                                      color: AppColors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                            ),
                          ),
                          // SizedBox(
                          //   height: 30,
                          //   width: 120,
                          //   child: CustomButton(
                          //     onPressed: () {},
                          //     title: 'More info',
                          //     gradient: null,
                          //     background:
                          //         AppColors.primaryColor.withValues(alpha: .1),
                          //     textColor: AppColors.primaryColor,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              BlocBuilder<StylistSellerDetailsCubit, StylistSellerDetailsState>(
                builder: (context, state) {
                  return Container(
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
                              AppText(
                                text: state.sellerDetails.data?.name ?? 'N/A',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              10.horizontalSpace,
                              if (state.sellerDetails.data?.status ==
                                  'verified')
                                Icon(
                                  Iconsax.verify5,
                                  color: Colors.green.shade500,
                                ),
                            ],
                          ),
                          AppText(
                            text: state.sellerDetails.data?.stylistProfile
                                    ?.businessName ??
                                '',
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
                              AppText(
                                text: state.sellerDetails.data?.averageRating
                                        ?.toString() ??
                                    '0',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              5.horizontalSpace,
                              AppText(
                                text:
                                    '(${state.sellerDetails.data?.reviewsCount ?? 0} Reviews)',
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
                              Expanded(
                                child: AppText(
                                  text: state.sellerDetails.data?.country ??
                                      'N/A',
                                  fontSize: 10,
                                  color: AppColors.grey3,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.grey.shade200,
                          ),
                          SizedBox(
                            height: 60.h,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      AppText(
                                        text:
                                            '${state.sellerDetails.data?.completedAppointmentsCount ?? 0}+',
                                        fontSize: 20,
                                        maxLines: 1,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryColor,
                                      ),
                                      const AppText(
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
                                Expanded(
                                  child: Column(
                                    children: [
                                      AppText(
                                        text:
                                            '${state.sellerDetails.data?.stylistProfile?.yearsOfExperience ?? 0}+ years',
                                        fontSize: 20,
                                        maxLines: 1,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryColor,
                                      ),
                                      const AppText(
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
                                Expanded(
                                  child: Column(
                                    children: [
                                      AppText(
                                        text: state.sellerDetails.data
                                                ?.responseTime ??
                                            'N/A',
                                        fontSize: 20,
                                        maxLines: 1,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryColor,
                                      ),
                                      const AppText(
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
                                      AppText(
                                        text:
                                            '${state.sellerDetails.data?.minPrice?.toDouble().formatAmount()} - ${state.sellerDetails.data?.maxPrice?.toDouble().formatAmount()} ',
                                        fontSize: 16,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      const AppText(
                                        text: 'Price range',
                                        fontSize: 12,
                                      ),
                                      5.verticalSpace,
                                      AppText(
                                        text: state.sellerDetails.data
                                                ?.nextAvailable ??
                                            'N/A',
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<StylistSellerDetailsCubit>()..init(seller: seller, id: id),
      child: this,
    );
  }
}

class ReviewsView extends StatelessWidget {
  const ReviewsView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StylistSellerDetailsCubit>().state;
    if (state.sellePortfolio.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final reviews = state.sellerDetails.data?.reviews ?? [];
    if (reviews.isEmpty) {
      return const Center(
        child: AppText(
          text: 'No reviews yet',
          color: AppColors.grey3,
        ),
      );
    }
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
                final review = reviews[index];
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
                            AppText(
                              text: review.appointment?.customer?.name ?? 'N/A',
                              fontWeight: FontWeight.bold,
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  ...List.generate(
                                    int.tryParse(review.rating.toString()) ?? 0,
                                    (index) => const WidgetSpan(
                                      child: Icon(
                                        Iconsax.star1,
                                        color: Colors.amber,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' ${review.createdAt?.toTimeAgo() ?? ''}',
                                    style: AppTextStyle.caption
                                        .copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            5.verticalSpace,
                            AppText(
                              text: review.comment ?? 'N/A',
                              fontSize: 12,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
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
              childCount: reviews.length,
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
    final state = context.watch<StylistSellerDetailsCubit>().state;
    if (state.sellePortfolio.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
              List.generate(state.sellerDetails.data?.mediaUrls?.length ?? 0,
                  (index) {
                return GestureDetector(
                  onTap: () {
                    if (state.sellerDetails.data?.mediaUrls?[index]
                            .completeImagePath() ==
                        null) {
                      return;
                    }
                    context.router.pushWidget(
                      FullScreenImageView(
                        imagePath: state.sellerDetails.data!.mediaUrls![index]
                            .completeImagePath(),
                      ),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: state.sellerDetails.data?.mediaUrls?[index]
                            .completeImagePath() ??
                        '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.error),
                    ),
                  ),
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
    return BlocBuilder<StylistSellerDetailsCubit, StylistSellerDetailsState>(
      builder: (context, state) {
        if (state.sellePortfolio.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final services = state.sellePortfolio.data?.data ?? [];
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
                itemExtent: 100.0.h,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final service = services[index];
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
                                AppText(
                                  text: service.title ?? 'N/A',
                                  maxLines: 1,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                AppText(
                                  text: service.description ?? 'N/A',
                                  fontSize: 12,
                                  maxLines: 1,
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
                                        text: ' ${service.duration ?? 'N/A'}',
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
                              AppText(
                                text: service.price?.formatAmount() ?? 'R0',
                                color: AppColors.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 120.w,
                                height: 30.h,
                                child: CustomButton(
                                  title: 'Book Now',
                                  onPressed: () {
                                    context.pushRoute(
                                      UpdateCreateAppointmentRoute(
                                        portfolio: service,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: services.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  const FullScreenImageView({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imagePath,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}
