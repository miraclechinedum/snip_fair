import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
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

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.defaultBoxShadow,
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.request_quote_outlined,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Payment Request',
                        style: AppTextStyle.subTitle2.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _StatusChip(status: pr.status),
                  ],
                ),
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
                    color: AppColors.blackShade1,
                  ),
                ),
                if (pr.bookingId != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Booking ID: ${pr.bookingId}',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (pr.description != null && pr.description!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    pr.description!,
                    style: AppTextStyle.body2.copyWith(color: AppColors.grey3),
                  ),
                ],
                SizedBox(height: 12.h),

                // Items list
                if (pr.items != null && pr.items!.isNotEmpty) ...[
                  ...pr.items!.map((item) => _ItemRow(item: item, currencyFormat: currencyFormat)),
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
                      ),
                    ),
                    Text(
                      currencyFormat.format(pr.totalAmount ?? 0),
                      style: AppTextStyle.subTitle1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),

                // Expiry
                if (pr.expiresAt != null && pr.isPending) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14.sp, color: AppColors.grey2),
                      SizedBox(width: 4.w),
                      Text(
                        'Expires ${DateFormat('d MMM y, HH:mm').format(pr.expiresAt!.toLocal())}',
                        style: AppTextStyle.caption.copyWith(color: AppColors.grey2),
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
  const _ItemRow({required this.item, required this.currencyFormat});
  final PaymentRequestItem item;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.quantity ?? 1}× ${item.name ?? ''}',
              style: AppTextStyle.body2.copyWith(color: AppColors.grey3),
            ),
          ),
          Text(
            currencyFormat.format(item.amount ?? 0),
            style: AppTextStyle.body2.copyWith(
              color: AppColors.blackShade1,
              fontWeight: FontWeight.w500,
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
