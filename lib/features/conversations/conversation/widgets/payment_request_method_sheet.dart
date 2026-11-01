import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/presentation/widgets/payment_method_selector.dart';

/// Lets the customer choose how to pay a chat payment request. Pops the
/// chosen method ('wallet' or 'card'), or null when dismissed.
class PaymentRequestMethodSheet extends StatefulWidget {
  const PaymentRequestMethodSheet({
    required this.amount,
    required this.walletBalance,
    super.key,
  });

  final double amount;

  /// Null when the balance could not be loaded.
  final num? walletBalance;

  @override
  State<PaymentRequestMethodSheet> createState() =>
      _PaymentRequestMethodSheetState();
}

class _PaymentRequestMethodSheetState extends State<PaymentRequestMethodSheet> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final walletBalance = widget.walletBalance?.toDouble();
    // Default to the wallet only when it is known to cover the full amount.
    final selected = _selected ??
        (walletBalance != null && walletBalance >= widget.amount
            ? 'wallet'
            : 'card');
    final shortfall =
        walletBalance == null ? 0.0 : widget.amount - walletBalance;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          12.verticalSpace,
          const ModalPill(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: 'Pay Request',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                4.verticalSpace,
                AppText(
                  text: 'Amount due: ${widget.amount.formatAmount()}',
                  color: AppColors.grey3,
                ),
                16.verticalSpace,
                PaymentMethodSelector(
                  selected: selected,
                  walletBalance: walletBalance,
                  onSelected: (method) => setState(() => _selected = method),
                ),
                if (walletBalance == null) ...[
                  8.verticalSpace,
                  const AppText(
                    key: Key('payment_request_wallet_unavailable'),
                    text: "We couldn't load your wallet balance. Your balance "
                        'will be checked when you pay from your wallet.',
                    fontSize: 12,
                    color: AppColors.warningText,
                  ),
                ] else if (selected == 'wallet' && shortfall > 0) ...[
                  8.verticalSpace,
                  AppText(
                    key: const Key('payment_request_wallet_shortfall'),
                    text: 'Your wallet is short by '
                        '${shortfall.formatAmount()}. You can top up '
                        'the difference by card on the next step.',
                    fontSize: 12,
                    color: AppColors.warningText,
                  ),
                ],
                16.verticalSpace,
                CustomButton(
                  key: const Key('payment_request_method_continue'),
                  title: 'Continue',
                  onPressed: () => Navigator.of(context).pop(selected),
                ),
                12.verticalSpace,
                CustomButton(
                  title: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                  gradient: null,
                  background: const Color(0xff374757),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
