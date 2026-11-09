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
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_attempt.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_failure.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_lookup.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_status.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';
import 'package:snip_fair/features/account/seller/earnings/views/seller_payout_settings_form_view.dart';
import 'package:snip_fair/features/account/seller/earnings/views/seller_escrow_breakdown_screen.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

@RoutePage()
class SellerEarningScreen extends StatelessWidget implements AutoRouteWrapper {
  const SellerEarningScreen({super.key});

  static const payoutErrorFallback =
      "We couldn't submit your payout request. Please try again.";
  static const settingsErrorFallback =
      "We couldn't update your payout settings. Please try again.";

  static const withdrawalsUnavailableMessage =
      'Withdrawals are temporarily unavailable. Your balance has not been '
      'deducted. Please try again later.';
  static const withdrawalConflictMessage =
      'This withdrawal conflicts with a previous request, so it was not '
      'submitted and nothing was deducted for it. Your transactions have '
      'been refreshed: please check them before starting a new withdrawal.';
  static const withdrawalSessionExpiredMessage =
      'Your session has expired. Please log in again. Your balance has not '
      'been deducted.';
  static const withdrawalForbiddenFallback =
      "Your account can't request withdrawals yet. Please complete your "
      'profile and verify your email, then try again.';
  static const withdrawalRateLimitedMessage =
      'Too many attempts. Please wait a minute and try again. Your balance '
      'has not been deducted.';
  static const withdrawalKeyRejectedMessage =
      "This version of the app can't request withdrawals. Please update the "
      'app and try again. Your balance has not been deducted.';
  static const withdrawalRejectedFallback =
      "We couldn't submit your withdrawal. Please check the amount and payout "
      'method and try again.';
  static const withdrawalUncertainMessage =
      "We couldn't confirm whether your withdrawal request went through. "
      'Your details have been kept: tap "Retry Request" to safely resend the '
      'same request. It will not be submitted twice.';

  static const supportEmail = 'support@snipfair.com';

  /// Smallest withdrawal the backend accepts, inclusive (Laravel `gte:10`).
  static const minimumWithdrawalCents = 1000;
  static const minimumWithdrawalMessage =
      'Minimum withdrawal amount is R10.00.';

  static const unreadableAttemptMessage =
      "An earlier withdrawal request saved on this device can't be read, so "
      "we can't tell whether it was accepted or safely resend it. Your "
      "transaction history can't prove it wasn't: it may not show yet. To "
      'make sure you are not paid out twice, new withdrawals are blocked on '
      'this device. Please contact $supportEmail.';
  static const conflictPendingMessage =
      'Your last withdrawal request conflicted with an earlier one and was '
      'not accepted. We need to reload your transactions before you can '
      'request another withdrawal.';
  static const storageUnavailableMessage =
      "We couldn't save your withdrawal request on this device, so it was "
      'not sent and your balance has not been deducted. Please try again.';

  /// What the stylist is told about an earlier withdrawal the lookup found.
  /// Only `paid` is ever described as sent to the bank, and never as received:
  /// the bank may take some time to credit it.
  static String recoveredWithdrawalMessage(WithdrawalRecord withdrawal) {
    final amount = withdrawal.amount.formatAmount();
    final status = switch (withdrawal.status) {
      WithdrawalRecordStatus.pending =>
        'Your withdrawal request for $amount was received and is waiting to '
            'be sent to your bank. It has not been paid yet.',
      WithdrawalRecordStatus.processing =>
        'Your withdrawal request for $amount was received and is being '
            'processed. It has not been paid yet.',
      WithdrawalRecordStatus.paid =>
        'Your withdrawal of $amount has been sent to your bank account. '
            'Depending on your bank, it may take some time to reflect in your '
            'account.',
      WithdrawalRecordStatus.failed =>
        'Your withdrawal request for $amount failed and was not paid.',
      WithdrawalRecordStatus.underReview =>
        'Your withdrawal request for $amount was received and is being '
            'reviewed by our team. It has not been paid yet.',
      WithdrawalRecordStatus.reversed =>
        'Your withdrawal request for $amount was reversed by the bank.',
      WithdrawalRecordStatus.closed =>
        'Your withdrawal request for $amount has been closed.',
      null => 'Your withdrawal request for $amount was received. Its current '
          'status cannot be shown here.',
    };
    final refundAmount = withdrawal.refund?.amount;
    final refund = withdrawal.refunded
        ? refundAmount != null
            ? ' ${refundAmount.formatAmount()} has been refunded to your '
                'Snipfair balance.'
            : ' The amount has been refunded to your Snipfair balance.'
        : switch (withdrawal.status) {
            WithdrawalRecordStatus.failed ||
            WithdrawalRecordStatus.reversed =>
              ' No refund has been recorded yet.',
            _ => '',
          };
    return '$status$refund It will not be submitted again.';
  }

  static String recoveryNotFoundMessage(WithdrawalAttempt attempt) =>
      'Your earlier withdrawal request for '
      '${attempt.amount.formatAmount()} has not been recorded. Tap Retry '
      'Request to send that same request again: it can never be paid out '
      'twice. A different withdrawal can only be started once this one is '
      'resolved.';

  static String recoveryBusyMessage(WithdrawalAttempt attempt) =>
      'Your earlier withdrawal request for '
      '${attempt.amount.formatAmount()} is still being processed. Please '
      'check again shortly. New withdrawals stay blocked until it is '
      'confirmed.';

  static String recoveryCheckingMessage(WithdrawalAttempt attempt) =>
      'Checking your earlier withdrawal request for '
      '${attempt.amount.formatAmount()}…';

  static const recoveryForbiddenMessage =
      "Your account can't check this withdrawal right now. New withdrawals "
      'stay blocked until it is confirmed. Please contact $supportEmail.';

  /// Why the form is locked to an earlier, unconfirmed request.
  static String unresolvedAttemptMessage(WithdrawalAttempt attempt) =>
      "We couldn't confirm your withdrawal request for "
      '${attempt.amount.formatAmount()}. It may already have been accepted, '
      "even if it doesn't appear in your transactions yet. Retry resends the "
      'exact same request, so it can never be paid out twice. A different '
      'withdrawal can only be started once this one is confirmed. If retrying '
      'keeps failing, contact $supportEmail.';

  /// The message for a failed withdrawal request. Only definite refusals
  /// (400/403/422) show the backend's own message; the rest use fixed copy
  /// that says whether the balance was touched and whether a retry is safe.
  static String withdrawalErrorMessage(Object? error) {
    if (error is WithdrawalBlockedException) {
      return switch (error.reason) {
        WithdrawalBlockReason.unresolvedAttempt =>
          'You have an earlier withdrawal request that has not been '
              'confirmed yet, and it may already have been accepted. Retry '
              'it before starting a different withdrawal, so you are not paid '
              'out twice.',
        WithdrawalBlockReason.unreadableAttempt => unreadableAttemptMessage,
        WithdrawalBlockReason.storageUnavailable => storageUnavailableMessage,
      };
    }
    switch (classifyWithdrawalFailure(error)) {
      case WithdrawalFailureKind.disabled:
        return withdrawalsUnavailableMessage;
      case WithdrawalFailureKind.conflict:
        return withdrawalConflictMessage;
      case WithdrawalFailureKind.keyRejected:
        return withdrawalKeyRejectedMessage;
      case WithdrawalFailureKind.unauthorized:
        return withdrawalSessionExpiredMessage;
      case WithdrawalFailureKind.rateLimited:
        return withdrawalRateLimitedMessage;
      case WithdrawalFailureKind.forbidden:
        return _backendRefusal(error, fallback: withdrawalForbiddenFallback);
      case WithdrawalFailureKind.rejected:
        return _backendRefusal(error, fallback: withdrawalRejectedFallback);
      case WithdrawalFailureKind.uncertain:
        if (error is! RemoteException) {
          debugPrint(
            '[EARNINGS] Unexpected payout error: ${error.runtimeType}',
          );
        }
        return withdrawalUncertainMessage;
    }
  }

  /// A refusal in the backend's words: each Laravel validation error (422
  /// `errors`) on its own line, else its `message`, without the "Ooops.. "
  /// prefix Laravel puts on withdrawal refusals.
  static String _backendRefusal(Object? error, {required String fallback}) {
    String clean(String text) => text
        .replaceFirst(RegExp(r'^O+ps\.*\s*', caseSensitive: false), '')
        .trim();

    if (error is RemoteException) {
      final fieldErrors = <String>{
        for (final value in error.errorResponse?.errors.values ?? <Object?>[])
          for (final text in value is List ? value : [value])
            if (text is String && clean(text).isNotEmpty) clean(text),
      };
      if (fieldErrors.isNotEmpty) return fieldErrors.join('\n');
    }
    final message = clean(payoutErrorMessage(error, fallback: fallback));
    return message.isEmpty ? fallback : message;
  }

  /// Success copy for an accepted (HTTP 204) withdrawal. It is a request,
  /// not a completed transfer: the bank payout happens afterwards.
  static String withdrawalSubmittedMessage(WithdrawalSubmission submission) {
    final amount = submission.amount.formatAmount();
    if (submission.replayed) {
      return 'Your withdrawal request for $amount had already been received, '
          'so it was not submitted again. You can follow its progress in '
          'Transactions.';
    }
    return 'Your withdrawal request for $amount has been submitted. The '
        'transfer to your bank has not completed yet. You can follow its '
        'progress in Transactions.';
  }

  /// The message for a failed payout action: the backend's own message when
  /// the failure is a [RemoteException] that carries one, otherwise
  /// [fallback]. Any other error type is logged by type only — its text
  /// never reaches the stylist.
  static String payoutErrorMessage(Object? error, {required String fallback}) {
    if (error is RemoteException) {
      final message = error.errorResponse?.message.trim();
      return message == null || message.isEmpty ? fallback : message;
    }
    debugPrint('[EARNINGS] Unexpected payout error: ${error.runtimeType}');
    return fallback;
  }

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
                  subtext: payoutErrorMessage(
                    state.updatePayoutSettingState.error,
                    fallback: settingsErrorFallback,
                  ),
                  onDoneCallback: (_) {},
                ),
              );
            }
          },
        ),
        BlocListener<EarningsCubit, EarningsState>(
          listenWhen: (previous, current) =>
              current.recoveredWithdrawal != null &&
              previous.recoveredWithdrawal != current.recoveredWithdrawal,
          listener: (context, state) {
            AppHelper.showAppDialog<void>(
              context,
              OnConfirmDialog(
                key: const Key('recovered_withdrawal_dialog'),
                title: 'Earlier Withdrawal Found',
                content: recoveredWithdrawalMessage(state.recoveredWithdrawal!),
                confirmText: 'OK',
                showCancel: false,
              ),
            );
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
                  compactIcon: true,
                  mainText: 'Withdrawal Request Submitted',
                  subtext: withdrawalSubmittedMessage(
                    state.requestPayoutState.data!,
                  ),
                  onDoneCallback: (_) {},
                ),
              );
              context.read<SellerProfileMgtCubit>().getProfileDetails(true);
            }

            if (state.requestPayoutState.hasError) {
              AppHelper.showAppDialog<void>(
                context,
                OnFailDialogContent(
                  subtext: withdrawalErrorMessage(
                    state.requestPayoutState.error,
                  ),
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
                // The sheet is on the root navigator, outside this route's
                // BlocProvider, so the cubit is handed over explicitly.
                modal: BlocProvider.value(
                  value: cubit,
                  child: BlocBuilder<EarningsCubit, EarningsState>(
                    buildWhen: (previous, current) =>
                        previous.pendingWithdrawal !=
                            current.pendingWithdrawal ||
                        previous.pendingWithdrawalUnreadable !=
                            current.pendingWithdrawalUnreadable ||
                        previous.withdrawalRecovery !=
                            current.withdrawalRecovery ||
                        previous.requestPayoutState.isLoading !=
                            current.requestPayoutState.isLoading,
                    builder: (context, state) => RequestPayoutFormWidget(
                      paymentMethods: state.paymentMethods.data ?? [],
                      pendingAttempt: state.pendingWithdrawal,
                      pendingAttemptUnreadable:
                          state.pendingWithdrawalUnreadable,
                      isRequestInFlight: state.requestPayoutState.isLoading,
                      onSubmit: (amount, paymentMethod) {
                        return cubit.requestPayout(paymentMethod, amount);
                      },
                      recoveryStatus: state.withdrawalRecovery,
                      onRetry: cubit.retryPendingWithdrawal,
                      onCheckStatus: cubit.checkPendingWithdrawal,
                      onResolveConflict: cubit.resolveWithdrawalConflict,
                    ),
                  ),
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
        ..getPaymentMethods()
        ..restorePendingWithdrawal(),
      child: this,
    );
  }
}

class TransactionsWidget extends StatefulWidget {
  const TransactionsWidget({
    required this.cubit,
    super.key,
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
    final refundedWithdrawals = refundedWithdrawalIds(transactions);
    final filteredTransactions = transactions.where((transaction) {
      // Platform commission rows aren't the stylist's money and don't affect
      // their balance — the backend's earningIndex endpoint already excludes
      // them, so this list stays consistent by doing the same.
      final matchesType = transaction.type != 'other';
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
      return matchesType && matchesStatus && matchesSearch;
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
                // A failed withdrawal's money comes back as a separate
                // `refund` row: a credit to the stylist.
                final isCredit =
                    transaction.type == 'earning' || transaction.isRefund;
                final isDebit = transaction.isWithdrawal;
                return ListTile(
                  key: ValueKey('transaction_${transaction.id}'),
                  // contentPadding: EdgeInsets.zero,
                  // Stylist ledger:
                  //   earning, refund → credit-in (green right-arrow)
                  //   withdraw        → debit-out (red left-arrow)
                  leading: isCredit
                      ? const Icon(
                          Iconsax.arrow_right_1,
                          color: Colors.green,
                        )
                      : isDebit
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
                          ),
                        ),
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
                      // Sign + colour must match the leading arrow direction
                      // above. Rules for the stylist ledger:
                      //   earning, refund → +, green (income)
                      //   withdraw        → −, red   (payout leaving)
                      //   anything else   → −, primaryColor
                      AppText(
                        text:
                            '${isCredit ? '+' : '-'}${transaction.amount?.formatAmount() ?? 'R0.00'}',
                        fontWeight: FontWeight.w600,
                        color: isCredit
                            ? Colors.green
                            : isDebit
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
                          key: Key('transaction_status_${transaction.id}'),
                          text: transactionStatusLabel(
                            transaction,
                            refundedWithdrawalIds: refundedWithdrawals,
                          ),
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
    required this.cubit,
    super.key,
  });

  final EarningsCubit cubit;

  /// Shown when a figure is missing or unreadable — never a made-up zero.
  static const unavailable = '—';

  /// A money figure as sent by the server (cents kept; zero stays zero).
  String _amount(num? value) {
    if (cubit.state.earnings.isLoading) return '********';
    return value?.formatAmount() ?? unavailable;
  }

  @override
  Widget build(BuildContext context) {
    final statistics = cubit.state.earnings.data?.statistics;
    return RefreshIndicator(
      onRefresh: () async {
        await cubit.getEarnings();
      },
      child: SingleChildScrollView(
        // Pull-to-refresh must work even when the error card is all there is.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (cubit.state.earnings.hasError) ...[
              _EarningsLoadError(onRetry: cubit.getEarnings),
              12.verticalSpace,
            ],
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
                    key: const Key('earnings_total_earned'),
                    text: _amount(statistics?.totalEarnings?.value),
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
                    key: const Key('earnings_available_balance'),
                    text: _amount(statistics?.totalBalance?.value),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            12.verticalSpace,
            // Tappable → opens the escrow breakdown screen. Uses a plain
            // MaterialPageRoute rather than the auto_route registry so we
            // don't need to regenerate routes.gr.dart.
            InkWell(
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const SellerEscrowBreakdownScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
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
                        AppText(
                          text: 'In Escrow',
                          color: Colors.grey.shade600,
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                      ],
                    ),
                    8.verticalSpace,
                    AppText(
                      key: const Key('earnings_in_escrow'),
                      text: _amount(statistics?.pendingRelease?.value),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    if (!cubit.state.earnings.isLoading &&
                        (statistics?.pendingRelease?.changeText?.isNotEmpty ??
                            false)) ...[
                      4.verticalSpace,
                      AppText(
                        text: statistics!.pendingRelease!.changeText!,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ],
                ),
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
                    key: const Key('earnings_total_withdrawn'),
                    text: _amount(statistics?.totalWithdrawn?.value),
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
                    key: const Key('earnings_pending_requests'),
                    text: cubit.state.earnings.isLoading
                        ? '********'
                        : statistics?.totalRequests?.value?.toString() ??
                            unavailable,
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
    this.pendingAttempt,
    this.pendingAttemptUnreadable = false,
    this.isRequestInFlight = false,
    this.recoveryStatus = WithdrawalRecoveryStatus.idle,
    this.onRetry,
    this.onCheckStatus,
    this.onResolveConflict,
    super.key,
  });

  final List<PaymentMethod> paymentMethods;

  /// Sends the withdrawal; completes with true once the backend accepted it.
  final Future<bool> Function(double amount, PaymentMethod method) onSubmit;

  /// The withdrawal being sent, or the last one not yet accepted. While it
  /// is unresolved the form is locked to its amount and method and the only
  /// action is to retry it (same idempotency key).
  final WithdrawalAttempt? pendingAttempt;

  /// A saved attempt could not be read: withdrawals stay blocked on this
  /// device (it may have been accepted and cannot be resent).
  final bool pendingAttemptUnreadable;

  /// A withdrawal is being sent, possibly from an earlier opening of this
  /// form: submitting is blocked until it settles.
  final bool isRequestInFlight;

  /// Where looking up [pendingAttempt] by its key stands.
  final WithdrawalRecoveryStatus recoveryStatus;

  /// Resends [pendingAttempt] exactly; true once accepted.
  final Future<bool> Function()? onRetry;

  /// Looks [pendingAttempt] up again (read-only).
  final Future<void> Function()? onCheckStatus;
  final Future<void> Function()? onResolveConflict;

  @override
  State<RequestPayoutFormWidget> createState() =>
      _RequestPayoutFormWidgetState();
}

class _RequestPayoutFormWidgetState extends State<RequestPayoutFormWidget> {
  double _amount = 0;
  PaymentMethod? _paymentMethod;
  bool _isSubmitting = false;
  bool _hasInvalidAmount = false;

  /// At most two decimal places: Laravel refuses finer amounts.
  static final _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  final FocusNode _focusNode = FocusNode();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showLockedDetails();
  }

  @override
  void didUpdateWidget(RequestPayoutFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingAttempt != oldWidget.pendingAttempt) {
      _showLockedDetails();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _amountController.dispose();
    super.dispose();
  }

  WithdrawalAttempt? get _lockedAttempt {
    final pending = widget.pendingAttempt;
    return pending != null && pending.isUnresolved ? pending : null;
  }

  /// While an attempt is unresolved the fields show exactly its details.
  void _showLockedDetails() {
    final locked = _lockedAttempt;
    if (locked == null) return;
    _amount = locked.amount;
    _amountController.text = locked.amount.toStringAsFixed(2);
    _hasInvalidAmount = false;
    _paymentMethod = _methodFor(locked) ?? _paymentMethod;
  }

  PaymentMethod? _methodFor(WithdrawalAttempt attempt) => widget.paymentMethods
      .where((method) => method.id.toString() == attempt.paymentMethodId)
      .firstOrNull;

  bool get _isBusy =>
      _isSubmitting ||
      widget.isRequestInFlight ||
      widget.recoveryStatus == WithdrawalRecoveryStatus.checking;

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

  void _onAmountChanged(String value) {
    final text = value.trim();
    setState(() {
      _amount = _amountPattern.hasMatch(text) ? double.parse(text) : 0;
      _hasInvalidAmount = text.isNotEmpty && !_amountPattern.hasMatch(text);
    });
  }

  /// Runs [action] with the button disabled; the form closes once a
  /// withdrawal is accepted and otherwise stays open with its details.
  Future<void> _run(Future<bool> Function() action) async {
    // A second tap can land before the rebuild that disables the button.
    if (_isBusy) return;
    setState(() => _isSubmitting = true);
    var submitted = false;
    try {
      submitted = await action();
    } catch (e) {
      if (mounted) {
        AppHelper.showSnackBar(
          context,
          message: 'Failed to submit payout request. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (submitted && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _handleSubmit() async {
    if (_isBusy) return;
    if (_hasInvalidAmount) {
      AppHelper.showSnackBar(
        context,
        message: 'Enter an amount in rands with at most two decimal places.',
      );
      return;
    }
    if (_amount <= 0 || _paymentMethod == null) {
      AppHelper.showSnackBar(
        context,
        message: 'Please select a payment method and amount',
      );
      return;
    }
    // New requests only: a retry resends its unresolved attempt unchanged.
    // Compared in whole cents (the amount has at most two decimals).
    if ((_amount * 100).round() <
        SellerEarningScreen.minimumWithdrawalCents) {
      AppHelper.showSnackBar(
        context,
        message: SellerEarningScreen.minimumWithdrawalMessage,
      );
      return;
    }
    await _run(() => widget.onSubmit(_amount, _paymentMethod!));
  }

  Future<void> _handleRetry() async {
    final onRetry = widget.onRetry;
    if (onRetry != null) await _run(onRetry);
  }

  Future<void> _handleSimpleAction(Future<void> Function()? action) async {
    if (action == null) return;
    await _run(() async {
      await action();
      return false;
    });
  }

  Future<void> _contactSupport() async {
    try {
      await AppHelper.sendMail(SellerEarningScreen.supportEmail);
    } catch (_) {
      if (mounted) {
        AppHelper.showSnackBar(
          context,
          message: 'Please email ${SellerEarningScreen.supportEmail}',
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Add any additional logic you need to handle when dependencies change
    if (widget.paymentMethods.isNotEmpty && _paymentMethod == null) {
      final locked = _lockedAttempt;
      _paymentMethod = (locked == null ? null : _methodFor(locked)) ??
          (widget.paymentMethods
                  .where(
                    (method) => method.isDefault ?? false,
                  )
                  .isNotEmpty
              ? widget.paymentMethods.firstWhere(
                  (method) => method.isDefault ?? false,
                )
              : widget.paymentMethods.first);
    }
  }

  Widget _primaryButton(WithdrawalAttempt? locked) {
    const key = Key('request_payout_submit');
    if (widget.pendingAttemptUnreadable) {
      // Nothing here can resolve it safely: no clearing, no new request.
      return CustomButton(
        key: key,
        title: 'Contact Support',
        onPressed: _contactSupport,
      );
    }
    if (locked?.status == WithdrawalAttemptStatus.conflict) {
      return CustomButton(
        key: key,
        title: 'Check Transactions',
        isLoading: _isBusy,
        onPressed: _isBusy
            ? null
            : () => _handleSimpleAction(widget.onResolveConflict),
      );
    }
    if (locked != null &&
        widget.recoveryStatus == WithdrawalRecoveryStatus.busy) {
      return CustomButton(
        key: key,
        title: 'Check Again',
        isLoading: _isBusy,
        onPressed:
            _isBusy ? null : () => _handleSimpleAction(widget.onCheckStatus),
      );
    }
    return CustomButton(
      key: key,
      title: locked != null ? 'Retry Request' : 'Request Payout',
      isLoading: _isBusy,
      onPressed:
          _isBusy ? null : (locked != null ? _handleRetry : _handleSubmit),
    );
  }

  String _lockedMessage(WithdrawalAttempt locked) {
    if (locked.status == WithdrawalAttemptStatus.conflict) {
      return SellerEarningScreen.conflictPendingMessage;
    }
    return switch (widget.recoveryStatus) {
      WithdrawalRecoveryStatus.checking =>
        SellerEarningScreen.recoveryCheckingMessage(locked),
      WithdrawalRecoveryStatus.notFound =>
        SellerEarningScreen.recoveryNotFoundMessage(locked),
      WithdrawalRecoveryStatus.busy =>
        SellerEarningScreen.recoveryBusyMessage(locked),
      WithdrawalRecoveryStatus.forbidden =>
        SellerEarningScreen.recoveryForbiddenMessage,
      WithdrawalRecoveryStatus.idle ||
      WithdrawalRecoveryStatus.unavailable =>
        SellerEarningScreen.unresolvedAttemptMessage(locked),
    };
  }

  @override
  Widget build(BuildContext context) {
    final locked = _lockedAttempt;
    final fieldsLocked = locked != null || widget.pendingAttemptUnreadable;
    final lockedMethodMissing = locked != null && _methodFor(locked) == null;
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
                        textController: _amountController,
                        label: 'Withdrawal Amount (R)',
                        readOnly: _isBusy || fieldsLocked,
                        isError: _hasInvalidAmount,
                        onChanged: _onAmountChanged,
                        inputType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                      // Rebuilt when locked so it shows the locked method.
                      key: ValueKey(locked?.paymentMethodId),
                      decoration: AppColors.inputDecoration.copyWith(
                        hintText: 'Select Payment Method',
                      ),
                      initialValue: lockedMethodMissing ? null : _paymentMethod,
                      disabledHint: lockedMethodMissing
                          ? Text('Payout method #${locked.paymentMethodId}')
                          : null,
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
                      onChanged: _isBusy || fieldsLocked
                          ? null
                          : (value) {
                              setState(() {
                                _paymentMethod = value;
                              });
                            },
                    ),
                    if (widget.pendingAttemptUnreadable) ...[
                      12.verticalSpace,
                      const _WithdrawalNotice(
                        key: Key('unreadable_withdrawal_notice'),
                        text: SellerEarningScreen.unreadableAttemptMessage,
                      ),
                    ] else if (locked != null && !widget.isRequestInFlight) ...[
                      12.verticalSpace,
                      _WithdrawalNotice(
                        key: const Key('pending_withdrawal_notice'),
                        text: _lockedMessage(locked),
                      ),
                      if (locked.outcomeUnknown)
                        Wrap(
                          alignment: WrapAlignment.end,
                          children: [
                            if (widget.recoveryStatus !=
                                WithdrawalRecoveryStatus.busy)
                              TextButton(
                                key: const Key('withdrawal_check_status'),
                                onPressed: _isBusy
                                    ? null
                                    : () => _handleSimpleAction(
                                          widget.onCheckStatus,
                                        ),
                                child: const Text('Check status'),
                              ),
                            TextButton(
                              key: const Key('withdrawal_contact_support'),
                              onPressed: _contactSupport,
                              child: const Text('Contact support'),
                            ),
                          ],
                        ),
                    ],
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
                    _primaryButton(locked),
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

/// A warning in the payout form about an earlier withdrawal request.
class _WithdrawalNotice extends StatelessWidget {
  const _WithdrawalNotice({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffFDECEC),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: AppText(
        text: text,
        fontSize: 12,
        color: AppColors.contentColorRed,
      ),
    );
  }
}

/// Overview banner for a failed `/stylist/earnings` load. The cause is in the
/// debug log (BaseRemoteSource); the stylist only sees a plain message.
class _EarningsLoadError extends StatelessWidget {
  const _EarningsLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('earnings_load_error'),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xffFDECEC),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          12.horizontalSpace,
          const Expanded(
            child: AppText(
              text: "We couldn't load your earnings. Please try again.",
              fontSize: 13,
            ),
          ),
          TextButton(
            key: const Key('earnings_retry'),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
