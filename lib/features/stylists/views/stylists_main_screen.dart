import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/features/explore/widgets/default_stylist_card.dart';

@RoutePage()
class StylistsMainScreen extends StatelessWidget {
  const StylistsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Hair',
      'Nails',
      'Widgs',
      'Bags',
      'Lashes',
      'Feet',
      'Pedicure'
    ];
    return Scaffold(
      body: Column(
        children: [
          16.verticalSpace,
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: index == 0
                      ? AppColors.primaryColor.withValues(alpha: .1)
                      : null,
                  border: Border.all(
                    color: AppColors.grey1,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Center(
                  child: AppText(
                    text: categories[index],
                  ),
                ),
              ),
              separatorBuilder: (_, __) => 10.horizontalSpace,
              itemCount: categories.length,
            ),
          ),
          16.verticalSpace,
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return const DefaultStylistCard();
              },
              separatorBuilder: (context, index) => 12.verticalSpace,
              itemCount: 10,
            ),
          ),
        ],
      ),
    );
  }
}
