import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:auto_route/annotations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:keyboard_actions/keyboard_actions_config.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';
import 'package:snip_fair/features/account/seller/earnings/views/seller_payout_settings_form_view.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

@RoutePage()
class SellerEarningScreen extends StatelessWidget implements AutoRouteWrapper {
  const SellerEarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EarningsCubit>();
    final tabs = [
      const Tab(text: 'Overview'),
      const Tab(text: 'Transactions'),
    ];
    return MultiBlocListener(
      listeners: [
        BlocListener<EarningsCubit, EarningsState>(
          listenWhen: (previous, current) =>
              previous.updatePayoutSettingState !=
              current.updatePayoutSettingState,
          listener: (context, state) {
            if (state.updatePayoutSettingState.hasSuccess) {
              context.read<SellerProfileMgtCubit>().getProfileDetails(true);
            }

            if (state.updatePayoutSettingState.hasError) {
              AppHelper.showAppDialog<void>(
                context,
                OnFailDialogContent(
                  subtext:
                      (state.updatePayoutSettingState.error! as RemoteException)
                              .errorResponse
                              ?.message ??
                          '',
                  onDoneCallback: (_) {},
                ),
              );
            }
          },
        ),
        BlocListener<EarningsCubit, EarningsState>(
          listenWhen: (previous, current) =>
              previous.requestPayoutState != current.requestPayoutState,
          listener: (context, state) {
            if (state.requestPayoutState.hasSuccess) {
              AppHelper.showAppDialog<void>(
                context,
                OnSuccessDialogContent(
                  mainText: 'Payout Requested',
                  subtext:
                      'Your payout request has been submitted successfully.',
                  onDoneCallback: (_) {},
                ),
              );
              context.read<SellerProfileMgtCubit>().getProfileDetails(true);
            }

            if (state.requestPayoutState.hasError) {
              AppHelper.showAppDialog<void>(
                context,
                OnFailDialogContent(
                  subtext: (state.requestPayoutState.error! as RemoteException)
                          .errorResponse
                          ?.message ??
                      '',
                  onDoneCallback: (_) {},
                ),
              );
            }
          },
        ),
      ],
      child: DefaultTabController(
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
              text: 'Earnings',
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
          floatingActionButton: GestureDetector(
            onTap: () {
              AppHelper.showCustomModalBottomSheet<void>(
                context: context,
                modal: RequestPayoutFormWidget(
                  paymentMethods: cubit.state.paymentMethods.data ?? [],
                  onSubmit: (amount, paymentMethod) {
                    return cubit.requestPayout(paymentMethod, amount);
                  },
                ),
                isDarkMode: false,
              );
            },
            child: Material(
              elevation: 6,
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.appgradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 10),
                    AppText(
                      text: 'Request Payout',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                OverviewWidget(cubit: cubit),
                TransactionsWidget(cubit: cubit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<EarningsCubit>()
        ..getEarnings()
        ..getPaymentMethods(),
      child: this,
    );
  }
}

class TransactionsWidget extends StatefulWidget {
  const TransactionsWidget({
    required this.cubit, super.key,
  });

  final EarningsCubit cubit;

  @override
  State<TransactionsWidget> createState() => _TransactionsWidgetState();
}

class _TransactionsWidgetState extends State<TransactionsWidget> {
  final statuses = [
    'all',
    'pending',
    'processing',
    'approved',
    'holding',
    'completed',
    'declined',
    'reversed',
    'failed',
  ];

  String searchQuery = '';
  String selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final transactions = widget.cubit.state.transactionsState.data ?? [];
    final filteredTransactions = transactions.where((transaction) {
      final matchesStatus = selectedStatus == 'all' ||
          (transaction.status != null &&
              transaction.status!.toLowerCase() == selectedStatus);
      final matchesSearch = searchQuery.isEmpty ||
          (transaction.description != null &&
              transaction.description!
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase())) ||
          (transaction.reference != null &&
              transaction.reference!
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()));
      return matchesStatus && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CustomTextField(
                    hint: 'Search Transactions',
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              8.horizontalSpace,
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownButtonFormField<String>(
                    decoration: AppColors.inputDecoration.copyWith(
                      labelText: 'Filter',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                    ),
                    isExpanded: true,
                    initialValue: selectedStatus,
                    style: AppTextStyle.body1.copyWith(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    items: statuses
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status[0].toUpperCase() + status.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await widget.cubit.fetchTransactions(isInitial: true);
            },
            child: InfiniteList(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 50),
              emptyBuilder: (context) => const Center(
                child: AppText(
                  text: 'No transactions found',
                ),
              ),
              centerEmpty: true,
              centerLoading: true,
              onFetchData: () {
                widget.cubit.fetchTransactions();
              },
              hasReachedMax:
                  widget.cubit.state.transactionsPaginationData.hasReachedMax,
              loadingBuilder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
              isLoading: widget.cubit.state.transactionsState.isLoading ||
                  widget.cubit.state.transactionsPaginationData.isLoadingMore,
              itemCount: filteredTransactions.length,
              separatorBuilder: (context, index) => 8.verticalSpace,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return ListTile(
                  // contentPadding: EdgeInsets.zero,
                  leading: transaction.type == 'earning' ||
                          transaction.type == 'other'
                      ? const Icon(
                          Iconsax.arrow_right_1,
                          color: Colors.green,
                        )
                      : transaction.type == 'refund'
                          ? const Icon(
                              Iconsax.refresh_circle,
                              color: Colors.green,
                            )
                          : transaction.type == 'withdraw'
                              ? const Icon(
                                  Iconsax.arrow_left,
                                  color: Colors.red,
                                )
                              : const Icon(Iconsax.bank),
                  title: AppText(
                    text: transaction.description ?? 'N/A',
                    fontWeight: FontWeight.w600,
                  ),
                  subtitle: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: AppColors.grey3,
                        fontSize: 12.sp,
                      ),
                      children: [
                        TextSpan(
                            text: 'Ref: ${transaction.reference}',
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 12,
                            ),),
                        const TextSpan(text: '\n'),
                        TextSpan(
                          text: transaction.createdAt != null
                              ? transaction.createdAt!
                                  .toLocal()
                                  .toLongDateString()
                              : 'N/A',
                        ),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text:
                            '${transaction.type == 'topup' || transaction.type == 'refund' || transaction.type == 'other' ? '+' : '-'}${transaction.amount?.formatAmount() ?? 'R0.00'}',
                        fontWeight: FontWeight.w600,
                        color: transaction.type == 'topup' ||
                                transaction.type == 'refund' ||
                                transaction.type == 'other'
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
                              : transaction.status == 'pending' ||
                                      transaction.status == 'processing'
                                  ? AppColors.contentColorOrange
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
                              : transaction.status == 'pending' ||
                                      transaction.status == 'processing'
                                  ? AppColors.contentColorOrange
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
    );
  }
}

class OverviewWidget extends StatelessWidget {
  const OverviewWidget({
    required this.cubit, super.key,
  });

  final EarningsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await cubit.getEarnings();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.appgradient,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: 'Total Earned',
                    color: Colors.white,
                  ),
                  8.verticalSpace,
                  AppText(
                    text: cubit.state.earnings.isLoading
                        ? '********'
                        : cubit.state.earnings.data?.statistics?.totalEarnings
                                ?.value
                                ?.formatAmount() ??
                            '0',
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            12.verticalSpace,
            Container(
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
                  AppText(
                    text: 'Available Balance',
                    color: Colors.grey.shade600,
                  ),
                  8.verticalSpace,
                  AppText(
                    text: cubit.state.earnings.isLoading
                        ? '********'
                        : cubit.state.earnings.data?.statistics?.totalBalance
                                ?.value
                                ?.formatAmount() ??
                            '0',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            12.verticalSpace,
            Container(
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
                  AppText(
                    text: 'Total Withdrawn',
                    color: Colors.grey.shade600,
                  ),
                  8.verticalSpace,
                  AppText(
                    text: cubit.state.earnings.isLoading
                        ? '********'
                        : cubit.state.earnings.data?.statistics?.totalWithdrawn
                                    ?.value.runtimeType ==
                                int
                            ? (cubit.state.earnings.data?.statistics
                                    ?.totalWithdrawn?.value as int)
                                .formatAmount()
                            : double.parse(
                                cubit.state.earnings.data?.statistics
                                    ?.totalWithdrawn?.value as String,
                              ).formatAmount(),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            12.verticalSpace,
            Container(
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
                  AppText(
                    text: 'Pending Requests',
                    color: Colors.grey.shade600,
                  ),
                  8.verticalSpace,
                  AppText(
                    text: cubit.state.earnings.isLoading
                        ? '********'
                        : cubit.state.earnings.data?.statistics?.totalRequests
                                ?.value
                                ?.toString() ??
                            '0',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            12.verticalSpace,
            Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText(
                        text: 'Payout Settings',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      AppText(
                        text: cubit.state.settings?.instantPayout != null
                            ? cubit.state.settings!.instantPayout!
                                ? 'Manual Payout'
                                : 'Automatic Payout'
                            : '',
                        fontSize: 12,
                      ),
                    ],
                  ),
                  const Divider(),
                  if (cubit.state.earnings.data?.paymentMethod == null)
                    const AppText(text: 'No Payment method')
                  else ...[
                    ListTile(
                      minLeadingWidth: 10,
                      leading: const Icon(
                        Iconsax.card,
                        size: 15,
                        color: Color(0xffDB297A),
                      ),
                      title: AppText(
                        text: cubit
                                .state.earnings.data!.paymentMethod!.bankName ??
                            '',
                      ),
                      subtitle: AppText(
                        text:
                            'Routing: ${cubit.state.earnings.data!.paymentMethod!.routingNumber} \nAccount: ${cubit.state.earnings.data!.paymentMethod!.accountNumber.showLast4Digits()}',
                        fontSize: 12,
                        color: AppColors.grey3,
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          context.pushRoute(
                            const SellerPaymentMethodsRoute(),
                          );
                        },
                        child: const Icon(
                          Iconsax.edit_2,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    12.verticalSpace,
                    Builder(
                      builder: (context) {
                        return TextButton.icon(
                          icon: const Icon(
                            Iconsax.setting,
                            size: 15,
                          ),
                          onPressed: () {
                            SellerPayoutSettingsFormWidget.show(context);
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                8,
                              ),
                            ),
                            textStyle: AppTextStyle.caption
                                .copyWith(fontWeight: FontWeight.w600),
                            foregroundColor: AppColors.black,
                            backgroundColor: const Color(0xffF6F7F8),
                          ),
                          label: const Text('Change Settings'),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            12.verticalSpace,
          ],
        ),
      ),
    );
  }
}

class RequestPayoutFormWidget extends StatefulWidget {
  const RequestPayoutFormWidget({
    required this.paymentMethods,
    required this.onSubmit,
    super.key,
  });

  final List<PaymentMethod> paymentMethods;
  final Future<void> Function(double amount, PaymentMethod method) onSubmit;

  @override
  State<RequestPayoutFormWidget> createState() =>
      _RequestPayoutFormWidgetState();
}

class _RequestPayoutFormWidgetState extends State<RequestPayoutFormWidget> {
  double _amount = 0;
  PaymentMethod? _paymentMethod;
  bool _isSubmitting = false;

  final FocusNode _focusNode = FocusNode();

  KeyboardActionsConfig get _keyboardActionsConfig {
    return KeyboardActionsConfig(
      keyboardBarColor: const Color(0xFFCAD1D9), //Apple keyboard color
      actions: [
        KeyboardActionsItem(
          focusNode: _focusNode,
          toolbarButtons: [
            (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primaryColor, //Done button color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }
          ],
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_amount == 0 || _paymentMethod == null) {
      AppHelper.showSnackBar(
        context,
        message: 'Please select a payment method and amount',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_amount, _paymentMethod!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      AppHelper.showSnackBar(
        context,
        message: 'Failed to submit payout request. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Add any additional logic you need to handle when dependencies change
    if (widget.paymentMethods.isNotEmpty && _paymentMethod == null) {
      _paymentMethod = widget.paymentMethods
              .where(
                (method) => method.isDefault ?? false,
              )
              .isNotEmpty
          ? widget.paymentMethods.firstWhere(
              (method) => method.isDefault ?? false,
            )
          : widget.paymentMethods.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const ModalPill(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      text: 'Payout Details',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    12.verticalSpace,
                    KeyboardActions(
                      config: _keyboardActionsConfig,
                      disableScroll: true,
                      child: CustomTextField(
                        focusNode: _focusNode,
                        label: 'Withdrawal Amount (R)',
                        onChanged: (v) => _amount = double.tryParse(v) ?? 0,
                        inputType: const TextInputType.numberWithOptions(
                            decimal: true,),
                        hint: '0.00',
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    12.verticalSpace,
                    const AppText(
                      text: 'Payout Method',
                      fontSize: 12,
                    ),
                    5.verticalSpace,
                    DropdownButtonFormField<PaymentMethod>(
                      decoration: AppColors.inputDecoration.copyWith(
                        hintText: 'Select Payment Method',
                      ),
                      initialValue: _paymentMethod,
                      items: widget.paymentMethods
                          .map(
                            (method) => DropdownMenuItem<PaymentMethod>(
                              value: method,
                              child: Text(
                                '${method.bankName} - ${method.accountNumber.showLast4Digits()}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
                    ),
                    12.verticalSpace,
                    const AppText(text: 'Note.'),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xfffa8740).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const AppText(
                        text:
                            'Payouts are processed on business days only. You will receive an email confirmation once your payout is processed.',
                        fontSize: 12,
                        color: Color(0xfffa8740),
                      ),
                    ),
                    16.verticalSpace,
                    CustomButton(
                      title: 'Request Payout',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleSubmit,
                    ),
                    12.verticalSpace,
                    CustomButton(
                      title: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(false),
                      gradient: null,
                      background: const Color(0xff374757),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
