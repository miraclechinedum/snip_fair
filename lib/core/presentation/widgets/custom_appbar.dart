import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.showLeadingArrow = true,
    this.shrinkAppBar = false,
    this.elevation = false,
    this.onBackPressed,
    this.actions,

    // ignore: avoid_field_initializers_in_const_classes
  }) : preferredSize = const Size.fromHeight(50);

  final String? title;
  final bool showLeadingArrow;
  final bool shrinkAppBar;
  final bool elevation;
  final void Function()? onBackPressed;
  final List<Widget>? actions;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize:
          const Size.fromHeight(kToolbarHeight + 55), // Set this height
      child: Container(
        padding: EdgeInsets.only(left: showLeadingArrow ? 5 : 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: elevation
              ? [
                  const BoxShadow(
                    color: AppColors.grey200,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (showLeadingArrow)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    side: BorderSide.none,
                    foregroundColor: AppColors.primaryGrey,
                    fixedSize: const Size(46, 46),
                    alignment: Alignment.center,
                  ),
                  onPressed: () {
                    if (onBackPressed != null) {
                      onBackPressed!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.black,
                  ),
                ),
              20.horizontalSpace,
              if (title != null)
                Align(
                  alignment: showLeadingArrow
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: AppText(
                    text: title!,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              if (actions != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
