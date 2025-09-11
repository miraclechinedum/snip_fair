import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnSuccessDialogContent extends StatelessWidget {
  const OnSuccessDialogContent({
    required this.subtext,
    this.onDoneCallback,
    this.buttonText,
    super.key,
  });
  final String subtext;
  final String? buttonText;
  final void Function(BuildContext)? onDoneCallback;

  @override
  Widget build(BuildContext context) {
    if (onDoneCallback == null) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
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
                  Icons.check_circle,
                  size: 60.sp,
                  color: const Color(0xff008000),
                )),

                10.verticalSpace,

                // success
                const AppText(
                  text: 'Success',
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
                  fontSize: 14,
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
}

class OnFailDialogContent extends StatelessWidget {
  const OnFailDialogContent({
    super.key,
    required this.subtext,
    this.buttonText,
    required this.onDoneCallback,
  });

  final String subtext;
  final String? buttonText;
  final void Function(BuildContext) onDoneCallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          // inserted widget
          Padding(
            padding: const EdgeInsets.all(24).dg,
            child: Column(
              children: [
                10.verticalSpace,

                // image
                Expanded(
                    child: Icon(
                  Icons.error,
                  size: 60.sp,
                  color: Colors.red,
                )),

                10.verticalSpace,

                // success
                const AppText(
                  text: 'Oops',
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),

                10.verticalSpace,

                // text
                AppText(
                  text: subtext,
                  color: AppColors.grey4,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                  fontSize: 14,
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
          )
        ],
      ),
    );
  }
}
