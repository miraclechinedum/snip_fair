import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/utils/utils.dart';

/// One row of the customer's transaction history (Payment History and the
/// wallet's Transaction History). The title is Laravel's description; for an
/// appointment payment that names the service and stylist, and a second line
/// adds the appointment's date/time and reference. Tapping opens the details.
class CustomerTransactionTile extends StatelessWidget {
  const CustomerTransactionTile({required this.transaction, super.key});

  final UserTransaction transaction;

  bool get _isIncoming =>
      transaction.type == 'topup' || transaction.type == 'refund';

  @override
  Widget build(BuildContext context) {
    final appointment =
        transaction.isAppointmentPayment ? transaction.appointment : null;
    final details = [
      appointment?.scheduleLabel,
      appointment?.reference,
    ].whereType<String>().join(' · ');

    return ListTile(
      key: Key('customer_transaction_${transaction.id}'),
      contentPadding: EdgeInsets.zero,
      onTap: () => showCustomerTransactionDetails(context, transaction),
      leading: _TransactionIcon(type: transaction.type),
      title: AppText(
        key: Key('customer_transaction_title_${transaction.id}'),
        text: transaction.description ?? 'N/A',
        fontWeight: FontWeight.w600,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (details.isNotEmpty)
            AppText(
              key: Key('customer_transaction_appointment_${transaction.id}'),
              text: details,
              color: AppColors.grey3,
              fontSize: 12,
              maxLines: 1,
            ),
          AppText(
            text: transaction.createdAt != null
                ? transaction.createdAt!.toLocal().toLongDateString()
                : 'N/A',
            color: AppColors.grey3,
            fontSize: 12,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppText(
            text: '${_isIncoming ? '+' : '-'}'
                '${transaction.amount?.formatAmount() ?? 'R0.00'}',
            fontWeight: FontWeight.w600,
            color: _isIncoming
                ? Colors.green
                : transaction.type == 'payment'
                    ? Colors.red
                    : AppColors.primaryColor,
          ),
          _StatusPill(status: transaction.status),
        ],
      ),
    );
  }
}

/// Bottom sheet with everything known about [transaction]; for an appointment
/// payment that includes the booking it paid for.
Future<void> showCustomerTransactionDetails(
  BuildContext context,
  UserTransaction transaction,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => CustomerTransactionDetails(transaction: transaction),
  );
}

class CustomerTransactionDetails extends StatelessWidget {
  const CustomerTransactionDetails({required this.transaction, super.key});

  final UserTransaction transaction;

  static String? paymentMethodLabel(String? method) => switch (method) {
        'card' => 'Card',
        'wallet' => 'Wallet',
        'deposit' => 'Deposit',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final appointment =
        transaction.isAppointmentPayment ? transaction.appointment : null;
    final rows = <(String, String?)>[
      ('Amount', transaction.amount?.formatAmount()),
      ('Status', _capitalise(transaction.status)),
      ('Date', transaction.createdAt?.toLocal().toLongDateString()),
      ('Payment method', paymentMethodLabel(transaction.paymentMethod)),
      if (appointment != null) ...[
        ('Service', appointment.serviceName),
        ('Stylist', appointment.stylistName),
        ('Appointment', appointment.scheduleLabel),
        ('Appointment reference', appointment.reference),
      ],
      ('Transaction reference', transaction.reference),
    ].where((row) => row.$2 != null && row.$2!.isNotEmpty).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              key: const Key('customer_transaction_details_title'),
              text: transaction.description ?? 'Transaction',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            12.verticalSpace,
            for (final (label, value) in rows)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppText(
                        text: label,
                        color: AppColors.grey3,
                        fontSize: 13,
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      flex: 3,
                      child: AppText(
                        key: Key('customer_transaction_detail_$label'),
                        text: value!,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String? _capitalise(String? value) => value == null || value.isEmpty
      ? null
      : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _TransactionIcon extends StatelessWidget {
  const _TransactionIcon({required this.type});

  final String? type;

  @override
  Widget build(BuildContext context) => switch (type) {
        'topup' => const Icon(Iconsax.arrow_right_1, color: Colors.green),
        'refund' => const Icon(Iconsax.refresh_circle, color: Colors.green),
        'payment' => const Icon(Iconsax.arrow_left, color: Colors.red),
        _ => const Icon(Iconsax.bank),
      };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final paid = status == 'approved' || status == 'completed';
    final color = paid
        ? Colors.green
        : status == 'pending'
            ? AppColors.contentColorYellow
            : AppColors.contentColorRed;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: AppText(
        text: status ?? 'N/A',
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
