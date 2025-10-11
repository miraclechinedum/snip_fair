import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_item.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/work/cubit/seller_works_cubit.dart';
import 'package:snip_fair/features/account/work/views/seller_work_form_view.dart';

@RoutePage()
class SellerWorkScreen extends StatefulWidget implements AutoRouteWrapper {
  const SellerWorkScreen({super.key, this.workItem});
  final WorkItem? workItem;

  @override
  State<SellerWorkScreen> createState() => _SellerWorkScreenState();

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SellerWorksCubit>()
        ..getWorkCategories()
        ..getWorkList(),
      child: this,
    );
  }
}

class _SellerWorkScreenState extends State<SellerWorkScreen> {
  bool _formShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_formShown && widget.workItem != null) {
      _formShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SellerWorkFormWidget.show(context, widget.workItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Work'),
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<SellerWorksCubit, SellerWorksState>(
            builder: (context, state) {
              if (state.worksList.isLoading) {
                return const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()));
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
                      context.read<SellerWorksCubit>().deleteWorkItem(work.id!);
                    },
                    onEdit: () => SellerWorkFormWidget.show(context, work),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: works.length,
              );
            },
          ),
        ),
      ),
    );
  }
}

class SellerWorkItemWidget extends StatelessWidget {
  const SellerWorkItemWidget({
    Key? key,
    required this.work,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final WorkItem work;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12).r,
        color: Colors.white,
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ColoredBox(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  child: CachedNetworkImage(
                    imageUrl: work.mediaUrls?.first.completeImagePath() ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: const CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.white,
                      child: Icon(
                        Icons.delete,
                        size: 15,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 47,
                  top: 8,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: const CircleAvatar(
                      backgroundColor: AppColors.white,
                      radius: 15,
                      child: Icon(
                        Iconsax.edit,
                        size: 15,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: work.title ?? 'N/A',
                    maxLines: 1,
                    fontWeight: FontWeight.w600,
                  ),
                  AppText(
                    text: work.category?.name ?? 'N/A',
                    maxLines: 1,
                    color: Colors.grey.shade700,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 15,
                      ),
                      4.horizontalSpace,
                      AppText(
                        text: '0',
                        color: Colors.grey.shade700,
                        fontSize: 10,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.favorite_border_outlined,
                        color: Colors.grey,
                        size: 15,
                      ),
                      4.horizontalSpace,
                      AppText(
                        text: '0 likes',
                        color: Colors.grey.shade700,
                        fontSize: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
