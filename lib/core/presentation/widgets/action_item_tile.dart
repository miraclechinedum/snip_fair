import 'package:flutter/material.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';

class ActionItemTileWidget extends StatelessWidget {
  const ActionItemTileWidget({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.iconLemon.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                child: icon,
              ),
              16.horizontalSpace,
              Expanded(
                child: AppText(
                  text: label,
                  fontWeight: FontWeight.bold,
                ),
              ),
              16.horizontalSpace,
              const Icon(
                Icons.arrow_right,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
