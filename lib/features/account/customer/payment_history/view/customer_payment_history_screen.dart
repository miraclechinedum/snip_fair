import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

@RoutePage()
class CustomerPaymentHistoryScreen extends StatelessWidget {
  const CustomerPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CustomerProfileMgtCubit>();
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Payment History',
        actions: [
          const Icon(
            Iconsax.export_1,
            color: AppColors.primaryColor,
          ),
          16.horizontalSpace,
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await cubit.getWalletTransactions();
                },
                child: InfiniteList(
                  shrinkWrap: true,
                  emptyBuilder: (context) => const Center(
                    child: AppText(
                      text: 'No transactions found',
                    ),
                  ),
                  centerEmpty: true,
                  centerLoading: true,
                  onFetchData: () {
                    cubit.getWalletTransactions(loadMore: true);
                  },
                  hasReachedMax:
                      cubit.state.transactionsPaginationData.hasReachedMax,
                  loadingBuilder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  isLoading: cubit.state.transactionsState.isLoading ||
                      cubit.state.transactionsPaginationData.isLoadingMore,
                  itemCount: cubit.state.transactionsState.data?.length ?? 0,
                  separatorBuilder: (context, index) => 8.verticalSpace,
                  itemBuilder: (context, index) {
                    final transaction =
                        cubit.state.transactionsState.data![index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: transaction.type == 'topup'
                          ? const Icon(
                              Iconsax.arrow_right_1,
                              color: Colors.green,
                            )
                          : transaction.type == 'refund'
                              ? const Icon(
                                  Iconsax.refresh_circle,
                                  color: Colors.green,
                                )
                              : transaction.type == 'payment'
                                  ? const Icon(
                                      Iconsax.arrow_left,
                                      color: Colors.red,
                                    )
                                  : const Icon(Iconsax.bank),
                      title: AppText(
                        text: transaction.description ?? 'N/A',
                        fontWeight: FontWeight.w600,
                      ),
                      subtitle: AppText(
                        text: transaction.createdAt != null
                            ? transaction.createdAt!
                                .toLocal()
                                .toLongDateString()
                            : 'N/A',
                        color: AppColors.grey3,
                        fontSize: 12,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText(
                            text:
                                '${transaction.type == 'topup' || transaction.type == 'refund' ? '+' : '-'}${transaction.amount?.formatAmount() ?? 'R0.00'}',
                            fontWeight: FontWeight.w600,
                            color: transaction.type == 'topup' ||
                                    transaction.type == 'refund'
                                ? Colors.green
                                : transaction.type == 'payment'
                                    ? Colors.red
                                    : AppColors.primaryColor,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: transaction.status == 'approved' ||
                                      transaction.status == 'completed'
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : transaction.status == 'pending'
                                      ? AppColors.contentColorYellow
                                          .withValues(alpha: 0.2)
                                      : AppColors.contentColorRed
                                          .withValues(alpha: 0.2),
                              // Adjust colors as needed
                              // color: AppColors.grey2,
                              // Adjust colors as needed

                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: AppText(
                              text: transaction.status ?? 'N/A',
                              color: transaction.status == 'approved' ||
                                      transaction.status == 'completed'
                                  ? Colors.green
                                  : transaction.status == 'pending'
                                      ? AppColors.contentColorYellow
                                      : AppColors.contentColorRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
