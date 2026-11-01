import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';

/// Wallet shortfall summary shown before topping up the difference by card.
/// Pops `true` when the customer chooses to proceed, `false` on cancel.
class PaymentSummaryWidget extends StatelessWidget {
  const PaymentSummaryWidget({
    required this.servicePrice,
    required this.walletBalance,
    this.priceLabel = 'Service Price',
    super.key,
  });

  final double servicePrice;
  final double walletBalance;

  /// Label for the amount being paid ('Service Price' for bookings).
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
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
                  text: 'Payment Summary',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                16.verticalSpace,
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey1),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            text: priceLabel,
                          ),
                          AppText(
                            text: servicePrice.formatAmount(),
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      8.verticalSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: 'Wallet Balance',
                          ),
                          AppText(
                            text: '-${walletBalance.formatAmount()}',
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: 'Amount to Pay',
                            fontWeight: FontWeight.w600,
                          ),
                          AppText(
                            text: (servicePrice - walletBalance)
                                .clamp(0, servicePrice)
                                .formatAmount(),
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
                CustomButton(
                  title: 'Proceed to Pay',
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                12.verticalSpace,
                CustomButton(
                  title: 'Cancel',
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
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
