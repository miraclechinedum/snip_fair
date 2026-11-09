import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';
import 'package:snip_fair/features/account/customer/payment_history/widgets/customer_transaction_tile.dart';

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
                    return CustomerTransactionTile(transaction: transaction);
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
