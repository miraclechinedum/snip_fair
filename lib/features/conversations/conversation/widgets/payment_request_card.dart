import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/presentation/widgets/payment_summary_widget.dart';
import 'package:snip_fair/core/services/analytics_service.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/payment_request_method_sheet.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request_status.dart';

class PaymentRequestCard extends StatefulWidget {
  const PaymentRequestCard({
    required this.paymentRequestId,
    super.key,
  });

  final int paymentRequestId;

  /// Opens the Peach hosted checkout. Replaceable in tests, where the
  /// WebView plugin is unavailable.
  @visibleForTesting
  static Future<bool> Function(BuildContext, CheckoutPaymentData)
      openCheckout = AppHelper.showPaymentDialog;

  @override
  State<PaymentRequestCard> createState() => _PaymentRequestCardState();
}

class _PaymentRequestCardState extends State<PaymentRequestCard> {
  PaymentRequest? _paymentRequest;
  bool _isLoading = true;
  String? _actionInProgress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<ConversationsCubit>();
    // Check cache first
    final cached = cubit.getCachedPaymentRequest(widget.paymentRequestId);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _paymentRequest = cached;
          _isLoading = false;
        });
      }
      return;
    }
    final result = await cubit.fetchPaymentRequest(widget.paymentRequestId);
    if (mounted) {
      setState(() {
        _paymentRequest = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _respond(String action) async {
    if (_actionInProgress != null) return;
    if (_paymentActions.contains(action)) return _runPayment(action);
    setState(() => _actionInProgress = action);
    final updated = await context
        .read<ConversationsCubit>()
        .respondToPaymentRequest(widget.paymentRequestId, action);
    if (mounted) {
      setState(() {
        if (updated != null) _paymentRequest = updated;
        _actionInProgress = null;
      });
    }
  }

  /// Customer payment actions, all serialised through [_runPayment]:
  /// Pay Now, Check Payment Status, Retry Payment (wallet `/pay` only),
  /// adding the backend's shortfall to the wallet by card, and — only when
  /// the customer picks it after native card payment was unavailable —
  /// adding the full amount to the wallet by card, then paying from it.
  static const _paymentActions = {
    'pay',
    'check_status',
    'retry_wallet',
    'add_funds',
    'topup_and_pay',
  };

  /// Runs one payment action. Nothing is charged before the customer chooses
  /// a method; progress and outcomes are tracked by [ConversationsCubit] per
  /// request, so this card (or a rebuilt one) always renders the current
  /// phase. The card's own loading state is cleared on every exit path.
  Future<void> _runPayment(String action) async {
    final id = widget.paymentRequestId;
    final cubit = context.read<ConversationsCubit>();
    final pr = _paymentRequest;
    final progress = cubit.paymentProgressFor(id);
    paymentRequestLog('Payment action "$action": id=$id '
        'status=${pr?.statusRaw} amount=${pr?.totalAmount} '
        'canPay=${pr?.canPay} phase=${progress.phase.name}');
    // An unresolved card payment can always be checked, even if the request
    // changed meanwhile — the top-up lands in the wallet either way.
    final checking =
        action == 'check_status' || progress.phase.isUnresolvedTopUp;
    final blocker = checking
        ? null
        : pr == null
            ? 'This payment request could not be loaded. '
                'Please reopen the chat.'
            : cubit.payNowBlocker(pr);
    if (blocker != null) {
      paymentRequestLog('Payment action blocked: id=$id reason="$blocker"');
      AppHelper.showSnackBar(context, message: blocker);
      return;
    }
    if (!cubit.beginPaymentRequestPayment(id)) {
      paymentRequestLog('Payment action ignored: id=$id already in progress');
      return;
    }
    setState(() => _actionInProgress = 'pay');
    try {
      if (checking) {
        // An unconfirmed card payment is checked, never paid for again.
        await cubit.checkCardPaymentStatus(id);
      } else if (action == 'retry_wallet' ||
          progress.phase ==
              PaymentRequestPaymentPhase.topUpSucceededPaymentPending) {
        // Money already in the wallet: retry only the wallet payment.
        await cubit.payFromWallet(id);
      } else if (action == 'add_funds') {
        await _addWalletFunds(cubit);
      } else if (action == 'topup_and_pay') {
        await _topUpThenPay(cubit, pr!.totalAmount!);
      } else {
        await _chooseAndPay(cubit, pr!);
      }
    } catch (e, stack) {
      paymentRequestLog('Payment action threw for id=$id: $e\n$stack');
      if (mounted) {
        AppHelper.showSnackBar(
          context,
          message: "We couldn't open payment options. Please try again.",
        );
      }
    } finally {
      cubit.endPaymentRequestPayment(id);
      if (mounted) setState(() => _actionInProgress = null);
    }
  }

  /// Pay Now: the Wallet / Card choice, then that payment.
  Future<void> _chooseAndPay(
    ConversationsCubit cubit,
    PaymentRequest pr,
  ) async {
    final id = widget.paymentRequestId;
    final walletBalance =
        (await cubit.loadWalletBalanceForPayment())?.toDouble();
    if (!mounted) return;

    final amount = pr.totalAmount!;
    paymentRequestLog('Opening payment options: id=$id '
        'wallet=${walletBalance ?? 'unavailable'}');
    final method = await AppHelper.showCustomModalBottomSheet<String>(
      context: context,
      modal: PaymentRequestMethodSheet(
        amount: amount,
        walletBalance: walletBalance,
      ),
      isDarkMode: false,
    );
    paymentRequestLog('Payment options closed: id=$id '
        'method=${method ?? 'none (dismissed)'}');
    if (method == null || !mounted) return;

    _logAnalytics(
      () => AnalyticsService.instance.logInitiateCheckout(amount: amount),
    );

    if (method == 'card') {
      // Native card checkout. If Laravel says card payment is unavailable,
      // nothing else is started: the card then offers the alternatives.
      await _payByNativeCard(cubit);
      return;
    }

    // Wallet: `/pay` decides. If the wallet is short, the backend's own
    // `shortfall` is offered as a card top-up (never local arithmetic).
    await cubit.payFromWallet(id);
    if (mounted &&
        cubit.paymentProgressFor(id).phase ==
            PaymentRequestPaymentPhase.awaitingWalletFunds) {
      await _addWalletFunds(cubit);
    }
  }

  /// Offers to add exactly the backend's `shortfall` to the wallet by card,
  /// confirmed by the customer on the payment summary. Never automatic.
  Future<void> _addWalletFunds(ConversationsCubit cubit) async {
    final id = widget.paymentRequestId;
    final progress = cubit.paymentProgressFor(id);
    final shortfall = progress.shortfall;
    if (shortfall == null || shortfall <= 0 || !mounted) return;
    final required =
        (progress.requiredAmount ?? _paymentRequest?.totalAmount ?? shortfall)
            .toDouble();
    final balance =
        (progress.walletBalance ?? (required - shortfall)).toDouble();
    final proceed = await AppHelper.showCustomModalBottomSheet<bool>(
      context: context,
      modal: PaymentSummaryWidget(
        servicePrice: required,
        walletBalance: balance,
        priceLabel: 'Amount Due',
      ),
      isDarkMode: false,
    );
    if (proceed != true || !mounted) return;
    await _payByCard(cubit, shortfall.toDouble());
  }

  /// The customer's explicit choice while native card payment is
  /// unavailable: add the request's full amount to the wallet by card,
  /// confirmed on the payment summary, then pay from the wallet.
  Future<void> _topUpThenPay(ConversationsCubit cubit, double amount) async {
    final proceed = await AppHelper.showAppDialog<bool>(
      context,
      OnConfirmDialog(
        key: const Key('payment_request_topup_consent'),
        title: 'Top up by card?',
        content: 'Add ${amount.formatAmount()} to your wallet by card. Once '
            'confirmed, this request is paid from your wallet.',
        confirmText: 'Add Funds & Pay',
        cancelText: 'Not now',
      ),
    );
    if (proceed != true || !mounted) return;
    await _payByCard(cubit, amount);
  }

  /// Pays by card through Laravel's native checkout for this request, using
  /// the same hosted checkout as bookings. However the checkout ends, the
  /// cubit then asks Laravel; returning from checkout is never proof.
  Future<void> _payByNativeCard(ConversationsCubit cubit) async {
    final id = widget.paymentRequestId;
    final checkout = await cubit.startCardCheckout(id);
    // Null: the reason is already in the request's payment progress.
    if (checkout == null) return;
    try {
      if (mounted) {
        peachLog('Payment request $id: card checkout opened '
            'payment=${checkout.paymentId} reused=${checkout.reused}');
        final result = await PaymentRequestCard.openCheckout(
          context,
          checkout.toCheckoutData(),
        );
        peachLog('Payment request $id: card checkout closed (result=$result)');
      } else {
        peachLog('Payment request $id: card gone before checkout opened');
      }
    } catch (e) {
      peachLog('Payment request $id: hosted checkout threw ${e.runtimeType}');
    } finally {
      unawaited(
        cubit.onCardCheckoutClosed(id).catchError((Object e) {
          paymentRequestLog('Verification after checkout failed: $e');
        }),
      );
    }
  }

  /// Analytics must never interrupt a payment (e.g. Firebase not ready).
  void _logAnalytics(Future<void> Function() event) {
    try {
      unawaited(
        event().catchError(
          (Object e) => paymentRequestLog('Analytics failed: $e'),
        ),
      );
    } catch (e) {
      paymentRequestLog('Analytics failed: $e');
    }
  }

  /// Tops up [amount] to the wallet by card via the existing Peach checkout,
  /// then pays from the wallet once the top-up is verified.
  ///
  /// However the checkout ends — the X, the shopper-result page, a dismissal
  /// or an error — verification is handed to the cubit without awaiting it:
  /// the card shows the request's phase (a bounded "Confirming…", then Check
  /// Payment Status) instead of a spinner tied to this action.
  Future<void> _payByCard(ConversationsCubit cubit, double amount) async {
    final id = widget.paymentRequestId;
    final checkout = await cubit.startCardTopUp(id, amount: amount);
    // Null: the reason is already in the request's payment progress.
    if (checkout == null) return;
    try {
      if (mounted) {
        peachLog(
          'Payment request $id: Peach checkout opened '
          'deposit=${checkout.depositId}',
        );
        final result = await PaymentRequestCard.openCheckout(context, checkout);
        // The WebView logs *how* it closed (X, shopper-result page, …);
        // `result` is never payment proof.
        peachLog('Payment request $id: Peach checkout closed (result=$result)');
      } else {
        peachLog('Payment request $id: card gone before checkout opened');
      }
    } catch (e) {
      peachLog('Payment request $id: hosted checkout threw ${e.runtimeType}');
    } finally {
      // Closing checkout is never proof of payment or of failure.
      unawaited(
        cubit.onCardCheckoutClosed(id).catchError((Object e) {
          paymentRequestLog('Verification after checkout failed: $e');
        }),
      );
    }
  }

  PaymentRequestPaymentProgress _progressIn(ConversationsState state) =>
      state.paymentProgress[widget.paymentRequestId] ??
      const PaymentRequestPaymentProgress();

  /// Reacts once per payment transition: tells the customer what happened
  /// and refreshes the wallet whenever money may have moved.
  void _onPaymentProgress(PaymentRequestPaymentProgress progress) {
    final paid = _paymentRequest;
    switch (progress.phase) {
      case PaymentRequestPaymentPhase.successful:
        _logAnalytics(
          () => AnalyticsService.instance.logPurchase(
            amount: paid?.totalAmount ?? 0,
            transactionId: widget.paymentRequestId.toString(),
          ),
        );
        _refreshWallet();
      case PaymentRequestPaymentPhase.topUpSucceededPaymentPending:
      case PaymentRequestPaymentPhase.awaitingWalletFunds:
      case PaymentRequestPaymentPhase.failed:
        _refreshWallet();
      default:
        break;
    }
    final message = progress.message;
    if (message != null && !progress.phase.isBusy) {
      AppHelper.showSnackBar(context, message: message);
    }
  }

  void _refreshWallet() {
    context.read<CustomerProfileMgtCubit>()
      ..getWallet(true)
      ..getWalletTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConversationsCubit, ConversationsState>(
          listenWhen: (prev, curr) =>
              curr.lastUpdatedPaymentRequestId == widget.paymentRequestId &&
              prev.paymentRequestUpdateSeq != curr.paymentRequestUpdateSeq,
          listener: (context, cState) {
            // The request was refreshed (a `payment_request` push, or a pay
            // attempt). Pick up the fresh cached value — every time, even
            // for repeated updates of the same request.
            final refreshed = context
                .read<ConversationsCubit>()
                .getCachedPaymentRequest(widget.paymentRequestId);
            if (refreshed != null && mounted) {
              setState(() => _paymentRequest = refreshed);
            }
          },
        ),
        BlocListener<ConversationsCubit, ConversationsState>(
          listenWhen: (prev, curr) =>
              _progressIn(prev).revision != _progressIn(curr).revision,
          listener: (context, cState) => _onPaymentProgress(_progressIn(cState)),
        ),
      ],
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _skeleton();
    }
    if (_paymentRequest == null) {
      return const SizedBox.shrink();
    }
    return _card(context, _paymentRequest!);
  }

  Widget _card(BuildContext context, PaymentRequest pr) {
    final isStylist = context.read<AppCubit>().state.isStylist;
    final currencyFormat = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);
    final style = _CardStyle.forStatus(pr.status);

    final card = Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: style.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.defaultBoxShadow,
        border: Border.all(color: style.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: style.headerBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  style.headerIcon,
                  color: style.headerForeground,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    style.headerTitle,
                    style: AppTextStyle.subTitle2.copyWith(
                      color: style.headerForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // "ACTION REQUIRED" caption only shown to the customer for
                // pending / accepted — the party who actually has to act.
                if (style.showActionRequired && !isStylist) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    margin: EdgeInsets.only(right: 6.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'ACTION REQUIRED',
                      style: AppTextStyle.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                _StatusChip(status: pr.status),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  pr.title ?? '',
                  style: AppTextStyle.subTitle1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: style.bodyText,
                  ),
                ),
                if (pr.bookingId != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Booking ID: ${pr.bookingId}',
                    style: AppTextStyle.caption.copyWith(
                      color: style.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (pr.description != null && pr.description!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    pr.description!,
                    style: AppTextStyle.body2.copyWith(color: style.mutedText),
                  ),
                ],
                SizedBox(height: 12.h),

                // Items list
                if (pr.items != null && pr.items!.isNotEmpty) ...[
                  ...pr.items!.map(
                    (item) => _ItemRow(
                      item: item,
                      currencyFormat: currencyFormat,
                      textColor: style.mutedText,
                      amountColor: style.bodyText,
                      strikeThrough: style.strikeThroughTotal,
                    ),
                  ),
                  Divider(color: AppColors.grey1, height: 20.h),
                ],

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyle.subTitle1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: style.bodyText,
                      ),
                    ),
                    Text(
                      currencyFormat.format(pr.totalAmount ?? 0),
                      style: AppTextStyle.subTitle1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: style.totalColor,
                        decoration: style.strikeThroughTotal
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),

                // Expiry — only meaningful while pending / accepted
                if (pr.expiresAt != null && (pr.isPending || pr.isAccepted)) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: AppColors.warningText,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Expires ${DateFormat('d MMM y, HH:mm').format(pr.expiresAt!.toLocal())}',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.warningText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                // Action buttons — only shown when request is actionable
                if (_shouldShowActions(pr, isStylist)) ...[
                  SizedBox(height: 14.h),
                  _ActionButtons(
                    pr: pr,
                    isStylist: isStylist,
                    actionInProgress: _actionInProgress,
                    paymentProgress: context.select(
                      (ConversationsCubit cubit) =>
                          cubit.paymentProgressFor(widget.paymentRequestId),
                    ),
                    onRespond: _respond,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!style.showAccentBar) return card;

    // Left-edge accent bar for "live/action-required" states — signals at a
    // glance that this card is not just decoration.
    return Stack(
      children: [
        card,
        Positioned(
          left: 16.w,
          top: 6.h,
          bottom: 6.h,
          child: Container(
            width: 4.w,
            decoration: BoxDecoration(
              color: style.accentBar,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                bottomLeft: Radius.circular(16.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _shouldShowActions(PaymentRequest pr, bool isStylist) {
    if (isStylist) return pr.isPending && (pr.canCancel ?? false);
    // Customer: pending → accept/decline, accepted → pay, everything else → nothing
    return pr.isPending || pr.isAccepted;
  }

  Widget _skeleton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      height: 160.h,
      decoration: BoxDecoration(
        color: AppColors.grey1,
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final PaymentRequestStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status) {
      case PaymentRequestStatus.pending:
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFE65100);
      case PaymentRequestStatus.accepted:
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
      case PaymentRequestStatus.paid:
        bg = const Color(0xFFE8F5E9);
        text = AppColors.success;
      case PaymentRequestStatus.declined:
      case PaymentRequestStatus.cancelled:
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
      case PaymentRequestStatus.expired:
        bg = AppColors.grey1;
        text = AppColors.grey3;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.label,
        style: AppTextStyle.caption.copyWith(
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single item row
// ---------------------------------------------------------------------------

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.currencyFormat,
    required this.textColor,
    required this.amountColor,
    required this.strikeThrough,
  });
  final PaymentRequestItem item;
  final NumberFormat currencyFormat;
  final Color textColor;
  final Color amountColor;
  final bool strikeThrough;

  @override
  Widget build(BuildContext context) {
    final decoration =
        strikeThrough ? TextDecoration.lineThrough : TextDecoration.none;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.quantity ?? 1}× ${item.name ?? ''}',
              style: AppTextStyle.body2.copyWith(
                color: textColor,
                decoration: decoration,
              ),
            ),
          ),
          Text(
            currencyFormat.format(item.amount ?? 0),
            style: AppTextStyle.body2.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w500,
              decoration: decoration,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action buttons row
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.pr,
    required this.isStylist,
    required this.actionInProgress,
    required this.paymentProgress,
    required this.onRespond,
  });

  final PaymentRequest pr;
  final bool isStylist;
  final String? actionInProgress;
  final PaymentRequestPaymentProgress paymentProgress;
  final void Function(String action) onRespond;

  Widget _button(
    String title,
    String action,
    Key? key,
    bool busy, {
    bool outline = false,
  }) {
    return CustomButton(
      key: key,
      title: title,
      isLoading: busy,
      onPressed: busy ? null : () => onRespond(action),
      isOutline: outline,
      borderColor: outline ? AppColors.primaryColor : AppColors.transparent,
      textColor: outline ? AppColors.primaryColor : AppColors.white,
      background: outline ? Colors.transparent : AppColors.primaryColor,
      gradient: outline ? null : AppColors.appgradient,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isStylist) {
      return CustomButton(
        title: 'Cancel Request',
        isLoading: actionInProgress == 'cancel',
        onPressed: actionInProgress != null ? null : () => onRespond('cancel'),
        isOutline: true,
        borderColor: const Color(0xFFC62828),
        textColor: const Color(0xFFC62828),
        background: Colors.transparent,
        gradient: null,
      );
    }

    // Customer view — strictly status-driven:
    // pending  → Accept + Decline
    // accepted → Pay Now only
    // anything else → no buttons (handled by _shouldShowActions)

    if (pr.isPending) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 6.w),
              child: CustomButton(
                title: 'Accept',
                isLoading: actionInProgress == 'accept',
                onPressed: actionInProgress != null ? null : () => onRespond('accept'),
                isOutline: true,
                borderColor: AppColors.primaryColor,
                textColor: AppColors.primaryColor,
                background: Colors.transparent,
                gradient: null,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 6.w),
              child: CustomButton(
                title: 'Decline',
                isLoading: actionInProgress == 'decline',
                onPressed: actionInProgress != null ? null : () => onRespond('decline'),
                isOutline: true,
                borderColor: const Color(0xFFC62828),
                textColor: const Color(0xFFC62828),
                background: Colors.transparent,
                gradient: null,
              ),
            ),
          ),
        ],
      );
    }

    if (pr.isAccepted) {
      final phase = paymentProgress.phase;
      final busy = actionInProgress != null || phase.isBusy;
      final shortfall = paymentProgress.shortfall;

      final String? note;
      final List<Widget> buttons;
      if (phase.isUnresolvedTopUp) {
        note = paymentProgress.message ??
            'Your card payment is being confirmed.';
        buttons = [
          _button('Check Payment Status', 'check_status',
              const Key('payment_request_check_status'), busy),
        ];
      } else if (phase ==
          PaymentRequestPaymentPhase.topUpSucceededPaymentPending) {
        note = 'Your card payment is in your wallet. '
            'This request is not paid yet.';
        buttons = [
          _button('Retry Payment', 'retry_wallet',
              const Key('payment_request_retry_wallet'), busy),
        ];
      } else if (phase == PaymentRequestPaymentPhase.cardUnavailable) {
        note = paymentProgress.message ??
            ConversationsCubit.cardUnavailableMessage;
        buttons = [
          _button('Pay from Wallet', 'retry_wallet',
              const Key('payment_request_pay_wallet'), busy),
          _button('Top Up & Pay', 'topup_and_pay',
              const Key('payment_request_topup_and_pay'), busy,
              outline: true),
        ];
      } else if (phase == PaymentRequestPaymentPhase.awaitingWalletFunds) {
        note = paymentProgress.message ??
            'Your wallet does not have enough to pay this request yet.';
        buttons = [
          if (shortfall != null && shortfall > 0)
            _button(
              'Add ${shortfall.toDouble().formatAmount()}',
              'add_funds',
              const Key('payment_request_add_funds'),
              busy,
            ),
          _button('Retry Payment', 'retry_wallet',
              const Key('payment_request_retry_wallet'), busy,
              outline: shortfall != null && shortfall > 0),
        ];
      } else {
        note = switch (phase) {
          PaymentRequestPaymentPhase.initializingCardCheckout =>
            'Starting your card payment…',
          PaymentRequestPaymentPhase.checkoutOpen =>
            'Complete the card payment in the checkout.',
          PaymentRequestPaymentPhase.verifyingTopUp =>
            'Confirming your card payment…',
          PaymentRequestPaymentPhase.payingFromWallet =>
            'Completing your payment…',
          _ => null,
        };
        buttons = [_button('Pay Now', 'pay', null, busy)];
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (note != null) ...[
            Text(
              note,
              key: const Key('payment_request_progress_note'),
              style: AppTextStyle.caption.copyWith(
                color: AppColors.warningText,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          for (final (index, button) in buttons.indexed) ...[
            if (index > 0) SizedBox(height: 8.h),
            button,
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Status-driven card styling
// ---------------------------------------------------------------------------

/// Bundle of visual tokens the card resolves from status once, so the build
/// method stays declarative and the palette doesn't leak through the widget
/// tree as inline hex.
class _CardStyle {
  const _CardStyle({
    required this.cardBackground,
    required this.cardBorder,
    required this.headerBackground,
    required this.headerForeground,
    required this.headerIcon,
    required this.headerTitle,
    required this.bodyText,
    required this.mutedText,
    required this.totalColor,
    required this.accentBar,
    required this.showAccentBar,
    required this.showActionRequired,
    required this.strikeThroughTotal,
  });

  factory _CardStyle.forStatus(PaymentRequestStatus status) {
    switch (status) {
      case PaymentRequestStatus.pending:
      case PaymentRequestStatus.accepted:
        // Live / action-required: warm amber treatment on white so the card
        // reads as "you have something to do here."
        return const _CardStyle(
          cardBackground: Colors.white,
          cardBorder: AppColors.warningBorder,
          headerBackground: AppColors.warningBg,
          headerForeground: AppColors.warningText,
          headerIcon: Icons.request_quote_outlined,
          headerTitle: 'Payment Request',
          bodyText: AppColors.blackShade1,
          mutedText: AppColors.grey3,
          totalColor: AppColors.warningText,
          accentBar: AppColors.warning,
          showAccentBar: true,
          showActionRequired: true,
          strikeThroughTotal: false,
        );
      case PaymentRequestStatus.paid:
        // Complete / historical: muted background, green header + check icon.
        return const _CardStyle(
          cardBackground: AppColors.grey5,
          cardBorder: AppColors.grey200,
          headerBackground: AppColors.successBg,
          headerForeground: AppColors.success,
          headerIcon: Icons.check_circle_outline,
          headerTitle: 'Paid',
          bodyText: AppColors.grey3,
          mutedText: AppColors.grey3,
          totalColor: AppColors.grey3,
          accentBar: AppColors.transparent,
          showAccentBar: false,
          showActionRequired: false,
          strikeThroughTotal: false,
        );
      case PaymentRequestStatus.declined:
      case PaymentRequestStatus.cancelled:
        // Dead by user action: muted, red-tinted header, struck total.
        return _CardStyle(
          cardBackground: AppColors.grey5,
          cardBorder: AppColors.grey200,
          headerBackground: AppColors.dangerBg,
          headerForeground: AppColors.dangerText,
          headerIcon: Icons.cancel_outlined,
          headerTitle: status == PaymentRequestStatus.declined
              ? 'Declined'
              : 'Cancelled',
          bodyText: AppColors.grey3,
          mutedText: AppColors.grey3,
          totalColor: AppColors.grey3,
          accentBar: AppColors.transparent,
          showAccentBar: false,
          showActionRequired: false,
          strikeThroughTotal: true,
        );
      case PaymentRequestStatus.expired:
        // Dead by timeout: fully greyed, timer icon.
        return const _CardStyle(
          cardBackground: AppColors.grey5,
          cardBorder: AppColors.grey200,
          headerBackground: AppColors.grey1,
          headerForeground: AppColors.grey3,
          headerIcon: Icons.timer_off_outlined,
          headerTitle: 'Expired',
          bodyText: AppColors.grey3,
          mutedText: AppColors.grey3,
          totalColor: AppColors.grey3,
          accentBar: AppColors.transparent,
          showAccentBar: false,
          showActionRequired: false,
          strikeThroughTotal: true,
        );
    }
  }

  final Color cardBackground;
  final Color cardBorder;
  final Color headerBackground;
  final Color headerForeground;
  final IconData headerIcon;
  final String headerTitle;
  final Color bodyText;
  final Color mutedText;
  final Color totalColor;
  final Color accentBar;
  final bool showAccentBar;
  final bool showActionRequired;
  final bool strikeThroughTotal;
}
