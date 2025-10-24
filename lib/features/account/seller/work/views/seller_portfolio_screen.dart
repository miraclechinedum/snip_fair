import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/features/account/seller/work/cubit/seller_works_cubit.dart';

import 'package:snip_fair/features/account/seller/work/views/seller_work_form_view.dart';
import 'package:snip_fair/features/account/seller/work/views/seller_work_screen.dart';

@RoutePage()
class SellerPortfolioScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const SellerPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Portfolio',
      ),
      floatingActionButton: GestureDetector(
        onTap: () => SellerWorkFormWidget.show(context),
        child: Material(
          elevation: 6,
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.appgradient,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 10),
                AppText(
                  text: 'Add Work',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<SellerWorksCubit>()
            ..getWorkCategories()
            ..getPortfolioStats()
            ..getWorkList();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              BlocBuilder<SellerWorksCubit, SellerWorksState>(
                builder: (context, state) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      border: Border.all(color: AppColors.grey1),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Iconsax.bag_happy,
                            size: 18,
                            color: Colors.blue,
                          ),
                          title: const AppText(
                            text: 'Total Works',
                          ),
                          trailing: AppText(
                            text: state.portfolioStats.data?.total?.works
                                    ?.toString() ??
                                '0',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(
                          height: 1,
                        ),
                        ListTile(
                          leading: const Icon(
                            Iconsax.heart5,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          title: const AppText(
                            text: 'Total Likes',
                          ),
                          trailing: AppText(
                            text: state.portfolioStats.data?.total?.likes
                                    ?.toString() ??
                                '0',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(
                          height: 1,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.amber,
                          ),
                          title: const AppText(
                            text: 'Average Rating',
                          ),
                          trailing: AppText(
                            text: state.portfolioStats.data?.averageRating
                                    ?.toString() ??
                                '0',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              12.verticalSpace,
              BlocBuilder<SellerWorksCubit, SellerWorksState>(
                builder: (context, state) {
                  if (state.worksList.isLoading) {
                    return const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final works = state.worksList.data?.data ?? [];
                  if (works.isEmpty) return const Text('No Data');

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final work = works[index];
                      return SellerWorkItemWidget(
                        work: work,
                        onDelete: () {
                          AppHelper.showAppDialog(
                            context,
                            OnConfirmDialog(
                              title: 'Delete Work ',
                              content:
                                  'Are you sure you want to delete this work item?',
                              onConfirmed: (_) {
                                context
                                    .read<SellerWorksCubit>()
                                    .deleteWorkItem(work.id!);
                              },
                            ),
                          );
                        },
                        onEdit: () => SellerWorkFormWidget.show(context, work),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: works.length,
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
      create: (context) => getIt<SellerWorksCubit>()
        ..getWorkCategories()
        ..getPortfolioStats()
        ..getWorkList(),
      child: this,
    );
  }
}
