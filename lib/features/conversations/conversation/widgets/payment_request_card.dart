import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/services/analytics_service.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request_status.dart';

class PaymentRequestCard extends StatefulWidget {
  const PaymentRequestCard({
    required this.paymentRequestId,
    super.key,
  });

  final int paymentRequestId;

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
    setState(() => _actionInProgress = action);
    if (action == 'pay') {
      unawaited(
        AnalyticsService.instance.logInitiateCheckout(
          amount: _paymentRequest?.totalAmount ?? 0,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConversationsCubit, ConversationsState>(
      listenWhen: (prev, curr) =>
          curr.lastUpdatedPaymentRequestId == widget.paymentRequestId &&
          prev.lastUpdatedPaymentRequestId != curr.lastUpdatedPaymentRequestId,
      listener: (context, cState) {
        // Payment request status was refreshed by a `payment_request` push
        // (e.g. 'pending' → 'paid'). Pick up the fresh cached value.
        final refreshed = context
            .read<ConversationsCubit>()
            .getCachedPaymentRequest(widget.paymentRequestId);
        if (refreshed != null && mounted) {
          setState(() => _paymentRequest = refreshed);
        }
      },
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
    required this.onRespond,
  });

  final PaymentRequest pr;
  final bool isStylist;
  final String? actionInProgress;
  final void Function(String action) onRespond;

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
      return CustomButton(
        title: 'Pay Now',
        isLoading: actionInProgress == 'pay',
        onPressed: actionInProgress != null ? null : () => onRespond('pay'),
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
