import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';

// ---------------------------------------------------------------------------
// Wallet vs card selector shared by every customer checkout (appointment
// booking, chat payment requests). Stateless: the caller owns the selection
// ('wallet' or 'card') and is notified through [onSelected].
// ---------------------------------------------------------------------------

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selected,
    required this.walletBalance,
    required this.onSelected,
    super.key,
  });

  final String selected;

  /// Null when the balance could not be loaded.
  final num? walletBalance;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey1),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'Payment Method',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          12.verticalSpace,
          _PaymentMethodTile(
            key: const Key('payment_method_wallet'),
            icon: Iconsax.wallet_2,
            title: 'Wallet',
            subtitle: walletBalance == null
                ? 'Balance unavailable'
                : 'Balance: ${walletBalance!.toDouble().formatAmount()}',
            selected: selected == 'wallet',
            onTap: () => onSelected('wallet'),
          ),
          8.verticalSpace,
          _PaymentMethodTile(
            key: const Key('payment_method_card'),
            icon: Iconsax.card,
            title: 'Card',
            subtitle: 'Pay securely by card',
            selected: selected == 'card',
            onTap: () => onSelected('card'),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.grey1,
            width: selected ? 1.5 : 1,
          ),
          color: selected
              ? AppColors.primaryColor.withOpacity(0.05)
              : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryColor : AppColors.grey3,
              size: 22,
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: title,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected
                        ? AppColors.primaryColor
                        : AppColors.blackShade1,
                  ),
                  2.verticalSpace,
                  AppText(
                    text: subtitle,
                    fontSize: 12,
                    color: AppColors.grey3,
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primaryColor : AppColors.grey2,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
