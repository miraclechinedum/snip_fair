import 'package:flutter/material.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/animation_button_effect.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.title,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.background = AppColors.primaryColor,
    this.textColor = AppColors.white,
    this.width = double.infinity,
    this.radius = 12,
    this.icon,
    this.borderColor = AppColors.transparent,
    this.iconIsTrailing = false,
    this.isOutline = false,
    this.gradient = const LinearGradient(
      colors: [Color(0xff7F80DC), Color(0xffD52A81)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  });
  final Icon? icon;
  final String title;
  final bool isLoading;
  final void Function()? onPressed;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final double width;
  final double radius;
  final bool iconIsTrailing;
  final bool isOutline;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isLoading) {
      child = Center(
        child: SizedBox.square(
          dimension: 30.h,
          child: const CircularProgressIndicator(
            color: AppColors.white,
          ),
        ),
      );
    } else {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!iconIsTrailing) icon ?? const SizedBox(),
          AppText(
            text: title,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isOutline ? background : textColor,
          ),
          if (iconIsTrailing) icon ?? const SizedBox(),
        ],
      );
    }
    if (isOutline) {
      return AnimationButtonEffect(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            disabledBackgroundColor: background.withValues(alpha: .4),
            disabledForegroundColor: textColor.withValues(alpha: .8),
            side: BorderSide(
              color: borderColor == AppColors.transparent
                  ? background
                  : borderColor,
              width: 2,
            ),
            elevation: 0,
            shadowColor: AppColors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius.r),
            ),
            minimumSize: Size(width.w, 48.h),
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    if (gradient != null) {
      return AnimationButtonEffect(
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(
                radius.r), // Optional: for rounded corners
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.transparent, // Make button background transparent
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.r),
              ),
              minimumSize: Size(width.w, 48.h),
            ),
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        ),
      );
    }
    return AnimationButtonEffect(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: background.withOpacity(0.4),
          disabledForegroundColor: textColor.withOpacity(0.8),
          elevation: 0,
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.r),
          ),
          minimumSize: Size(width.w, 48.h),
          backgroundColor: background,
        ),
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
