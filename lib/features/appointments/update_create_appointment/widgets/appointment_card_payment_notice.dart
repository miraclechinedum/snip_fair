import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';

/// Shown on an opened, unpaid card booking: what happened to its payment and
/// what the customer can do — retry it when Peach confirmed it cancelled or
/// failed, or check it again while Peach has not confirmed it yet.
class AppointmentCardPaymentNotice extends StatelessWidget {
  const AppointmentCardPaymentNotice({
    required this.payment,
    required this.isBusy,
    required this.onRetry,
    required this.onCheckStatus,
    super.key,
  });

  final AppointmentCardPayment payment;

  /// A payment is being started or checked: both actions wait.
  final bool isBusy;
  final VoidCallback onRetry;
  final VoidCallback onCheckStatus;

  @override
  Widget build(BuildContext context) {
    final unpaid = !payment.isAwaitingConfirmation;
    final color = unpaid ? AppColors.contentColorRed : Colors.orange;
    return Container(
      key: const Key('appointment_card_payment_notice'),
      width: double.infinity,
      margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: payment.statusLabel,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          6.verticalSpace,
          AppText(
            key: const Key('appointment_card_payment_message'),
            text: payment.message ??
                (unpaid
                    ? 'This appointment has not been paid.'
                    : 'Your card payment has not been confirmed yet.'),
            fontSize: 13,
          ),
          if (payment.canRetry) ...[
            12.verticalSpace,
            CustomButton(
              key: const Key('appointment_card_payment_retry'),
              title: 'Retry Payment',
              isLoading: isBusy,
              onPressed: isBusy ? null : onRetry,
            ),
          ] else if (payment.isAwaitingConfirmation &&
              payment.depositId != null) ...[
            12.verticalSpace,
            CustomButton(
              key: const Key('appointment_card_payment_check'),
              title: 'Check Payment Status',
              isLoading: isBusy,
              onPressed: isBusy ? null : onCheckStatus,
              gradient: null,
              background: Colors.white,
              textColor: AppColors.black,
              borderColor: AppColors.grey1,
              isOutline: true,
            ),
          ],
        ],
      ),
    );
  }
}
