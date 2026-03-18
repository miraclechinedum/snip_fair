import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
// ignore_for_file: unawaited_futures

@RoutePage()
class CustomerWalletScreen extends StatelessWidget {
  const CustomerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CustomerProfileMgtCubit>();
    return Scaffold(
      appBar: const CustomAppBar(title: 'Wallet'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            cubit
              ..getWallet(true)
              ..getWalletTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top, // Ensure content fills screen
              ),
              child: Column(
                children: [
                  _buildWalletBalanceCard(cubit),
                  12.verticalSpace,
                  TextButton(
                    onPressed: () {
                      AppHelper.showCustomModalBottomSheet(
                        context: context,
                        modal: const TopUpWalletWidget(),
                        isDarkMode: false,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: AppColors.backgroundGreen,
                      foregroundColor: Colors.white,
                      textStyle: AppTextStyle.subTitle2.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Top-up Wallet'),
                  ),
                  12.verticalSpace,
                  Expanded(
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            text: 'Transaction History',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          12.verticalSpace,
                          Expanded(
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
                              hasReachedMax: cubit.state.transactionsPaginationData.hasReachedMax,
                              loadingBuilder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              isLoading: cubit.state.transactionsState.isLoading ||
                                  cubit.state.transactionsPaginationData.isLoadingMore,
                              itemCount: cubit.state.transactionsState.data?.length ?? 0,
                              separatorBuilder: (context, index) => 8.verticalSpace,
                              itemBuilder: (context, index) {
                                final transaction = cubit.state.transactionsState.data![index];
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
                                        ? transaction.createdAt!.toLocal().toLongDateString()
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container _buildWalletBalanceCard(CustomerProfileMgtCubit cubit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.appgradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Wallet Balance',
            style: AppTextStyle.subTitle2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cubit.state.walletState.data?.stats?.currentBalance?.formatAmount() ?? 'R0.00',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const AppText(
            text: 'Current Balance',
            color: Colors.white,
            fontSize: 12,
          ),
          Divider(
            color: Colors.white.withOpacity(0.5),
            height: 24.h,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  AppText(
                    text:
                        cubit.state.walletState.data?.stats?.totalTopups?.formatAmount() ?? 'R0.00',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  const AppText(
                    text: 'Total Top-ups',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ],
              ),
              Column(
                children: [
                  AppText(
                    text: cubit.state.walletState.data?.stats?.totalRefunds?.formatAmount() ??
                        'R0.00',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  const AppText(
                    text: 'Total Refunds',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ],
              ),
            ],
          ),
          Divider(
            color: Colors.white.withOpacity(0.5),
            height: 24.h,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  AppText(
                    text:
                        cubit.state.walletState.data?.stats?.pendingTransactions?.toString() ?? '0',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  const AppText(
                    text: 'Pending',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ],
              ),
              Column(
                children: [
                  AppText(
                    text: cubit.state.transactionsState.data?.length.toString() ?? '0',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  const AppText(
                    text: 'Transactions',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TopUpWalletWidget extends StatefulWidget {
  const TopUpWalletWidget({super.key});

  @override
  State<TopUpWalletWidget> createState() => _TopUpWalletWidgetState();
}

class _TopUpWalletWidgetState extends State<TopUpWalletWidget> {
  final TextEditingController _amountController = TextEditingController();

  void _topUpWallet(num amount) {
    if (amount <= 0) {
      AppHelper.showSnackBar(context, message: 'Please enter a valid amount');
      return;
    }
    context
        .read<CustomerProfileMgtCubit>()
        .initialisePayfastDeposit(type: 'topup', amount: amount.toString());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerProfileMgtCubit, CustomerProfileMgtState>(
      listenWhen: (previous, current) =>
          previous.initializePaymentState != current.initializePaymentState,
      listener: (context, state) async {
        if (state.initializePaymentState.hasSuccess) {
          final result = await AppHelper.showPaymentDialog(
            context,
            state.initializePaymentState.data!,
          );

          if (result) {
            context.read<CustomerProfileMgtCubit>()
              ..getWallet(true)
              ..getWalletTransactions();
          }
          if (context.mounted) {
            context.router.pop();
          }
        }
      },
      child: BlocBuilder<CustomerProfileMgtCubit, CustomerProfileMgtState>(
        builder: (context, state) {
          if (state.initializePaymentState.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 100),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              12.verticalSpace,
              const ModalPill(),
              12.verticalSpace,
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.wallet_2,
                          color: AppColors.primaryColor,
                        ),
                        8.horizontalSpace,
                        const AppText(
                          text: 'Top-up Wallet',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    12.verticalSpace,
                    const AppText(
                      text: 'Quick amounts',
                      fontSize: 10,
                    ),
                    10.verticalSpace,
                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      shrinkWrap: true,
                      childAspectRatio: 25 / 9,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _AmountChip(
                          amount: 50,
                          onTap: () {
                            _topUpWallet(50);
                          },
                        ),
                        _AmountChip(
                          amount: 100,
                          onTap: () {
                            _topUpWallet(100);
                          },
                        ),
                        _AmountChip(
                          amount: 200,
                          onTap: () {
                            _topUpWallet(200);
                          },
                        ),
                        _AmountChip(
                          amount: 500,
                          onTap: () {
                            _topUpWallet(500);
                          },
                        ),
                        _AmountChip(
                          amount: 1000,
                          onTap: () {
                            _topUpWallet(1000);
                          },
                        ),
                        _AmountChip(
                          amount: 2000,
                          onTap: () {
                            _topUpWallet(2000);
                          },
                        ),
                      ],
                    ),
                    12.verticalSpace,
                    const AppText(
                      text: 'Custom amount',
                      fontSize: 12,
                    ),
                    5.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            textController: _amountController,
                            hint: 'Enter amount',
                            inputType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: const [],
                          ),
                        ),
                        12.horizontalSpace,
                        ElevatedButton(
                          onPressed: () {
                            if (_amountController.text.isEmpty) {
                              AppHelper.showSnackBar(
                                context,
                                message: 'Please enter an amount',
                              );
                              return;
                            }
                            final amount = num.tryParse(_amountController.text);
                            if (amount == null) {
                              AppHelper.showSnackBar(
                                context,
                                message: 'Please enter a valid amount',
                              );
                              return;
                            }
                            _topUpWallet(amount);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            textStyle: AppTextStyle.subTitle2.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            minimumSize: const Size(48, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    40.verticalSpace,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.amount, this.onTap});
  final int amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Center(
          child: AppText(
            text: amount.formatAmount(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
