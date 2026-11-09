import 'dart:async';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';

class OnSuccessDialogContent extends StatelessWidget {
  const OnSuccessDialogContent({
    required this.subtext,
    this.onDoneCallback,
    this.buttonText,
    this.mainText,
    this.compactIcon = false,
    super.key,
  });
  final String subtext;
  final String? mainText;
  final String? buttonText;
  final void Function(BuildContext)? onDoneCallback;

  /// A small check in a light-green circle, with the content centred and
  /// scrollable, instead of the large square glyph in an `Expanded` — which
  /// paints past its box (over the heading) when a long message leaves it
  /// less than its size. Opt-in, so other dialogs keep their look.
  final bool compactIcon;

  static const successColor = Color(0xff008000);

  @override
  Widget build(BuildContext context) {
    if (onDoneCallback == null) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
    if (compactIcon) return _buildCompact(context);
    return SizedBox(
      // height: (context.heightPx * 0.5),
      width: double.infinity,
      child: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          // inserted widget
          Padding(
            padding: const EdgeInsets.all(24).dg,
            child: Column(
              children: [
                15.verticalSpace,

                // image
                Expanded(
                  child: Icon(
                    Iconsax.tick_square,
                    size: 100.sp,
                    color: const Color(0xff008000),
                  ),
                ),

                10.verticalSpace,

                // success
                AppText(
                  text: mainText ?? 'Success',
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),

                10.verticalSpace,

                // text
                AppText(
                  text: subtext,
                  color: AppColors.grey3,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                ),

                15.verticalSpace,

                // button
                if (onDoneCallback != null)
                  CustomButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDoneCallback?.call(context);
                    },
                    title: buttonText ?? 'Continue',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Icon, heading, message and button sized to their content and centred in
  /// the dialog; scrolls instead of overflowing when the dialog is short
  /// (small screens, large text).
  Widget _buildCompact(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8).dg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SuccessBadge(key: Key('success_dialog_icon')),
              16.verticalSpace,
              AppText(
                text: mainText ?? 'Success',
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                textAlign: TextAlign.center,
              ),
              8.verticalSpace,
              AppText(
                text: subtext,
                color: AppColors.grey3,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
              if (onDoneCallback != null) ...[
                24.verticalSpace,
                CustomButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDoneCallback?.call(context);
                  },
                  title: buttonText ?? 'Continue',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A 56 × 56 light-green circle holding a 32 px green check. Fixed logical
/// sizes, so it never outgrows its box.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: OnSuccessDialogContent.successColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 32,
        color: OnSuccessDialogContent.successColor,
      ),
    );
  }
}

class OnFailDialogContent extends StatelessWidget {
  const OnFailDialogContent({
    required this.subtext,
    required this.onDoneCallback,
    super.key,
    this.buttonText,
  });

  final String subtext;
  final String? buttonText;
  final void Function(BuildContext) onDoneCallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          // inserted widget
          Padding(
            padding: const EdgeInsets.all(24).dg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      10.verticalSpace,

                      // image
                      Icon(
                        Icons.error_outline,
                        size: 70.sp,
                        color: Colors.red,
                      ),

                      40.verticalSpace,

                      // success
                      const AppText(
                        text: 'Error!!',
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),

                      10.verticalSpace,

                      // text
                      AppText(
                        text: subtext,
                        color: AppColors.contentColorRed,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                15.verticalSpace,

                // button
                CustomButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDoneCallback(context);
                  },
                  title: buttonText ?? 'Try Again',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BiometricModal extends StatelessWidget {
  const BiometricModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const AppText(
            text: 'Sign In',
            fontWeight: FontWeight.bold,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SvgPicture.asset('assets/icons/outline/fingerprint_bare.svg'),
              5.horizontalSpace,
              const AppText(text: 'Scan your fingerprint'),
            ],
          ),
          const AppText(
            text: 'Cancel',
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

class OnConfirmDialog extends StatelessWidget {
  const OnConfirmDialog({
    super.key,
    this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirmed,
    this.onCancelled,
    this.confirmIsDestructive = false,
    this.showCancel = true,
    this.icon,
  });

  final String? title;
  final String content;
  final String confirmText;
  final String cancelText;
  final void Function(BuildContext)? onConfirmed;
  final void Function(BuildContext)? onCancelled;
  final bool confirmIsDestructive;
  final bool showCancel;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(24).r,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(),
            if (icon != null) ...[
              Center(child: icon),
              12.verticalSpace,
            ],
            if (title != null) ...[
              AppText(
                text: title!,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                textAlign: TextAlign.center,
              ),
              8.verticalSpace,
            ],
            AppText(
              text: content,
              color: AppColors.grey3,
              textAlign: TextAlign.center,
            ),
            16.verticalSpace,
            // buttons
            if (showCancel)
              Column(
                children: [
                  12.verticalSpace,
                  CustomButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                      onConfirmed?.call(context);
                    },
                    title: confirmText,
                  ),
                  12.verticalSpace,
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                      onCancelled?.call(context);
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size(double.infinity, 48.sp),
                    ),
                    child: AppText(
                      text: cancelText,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    onConfirmed?.call(context);
                  },
                  title: confirmText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
