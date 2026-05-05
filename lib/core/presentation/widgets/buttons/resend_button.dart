import 'package:flutter/material.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';

class ResendButton extends StatelessWidget {
  const ResendButton({
    required this.title,
    required this.onPressed,
    super.key,
    this.iconData = Icons.refresh,
    this.isTimeExpired = false,
    this.isResending = false,
  });
  final String title;
  final IconData iconData;
  final bool isTimeExpired;
  final bool isResending;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(97, 46),
        backgroundColor: AppColors.black,
      ),
      onPressed: onPressed,
      child: isTimeExpired
          ? isResending
              ? const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    color: AppColors.white,
                  ),
                )
              : Icon(
                  iconData,
                  color: AppColors.white,
                  size: 20,
                )
          : Text(
              title,
              style: AppTextStyle.body1.copyWith(
                fontSize: 15,
                color: AppColors.white,
              ),
            ),
    );
  }
}
