import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/animation_button_effect.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/gen/assets.gen.dart';

class TopStylistCard extends StatelessWidget {
  const TopStylistCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.router.push(const StylistProfileRoute());
      },
      child: AnimationButtonEffect(
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://snipfair.com/storage/works/media/sMFZVSnLU7yrq3qwMjV1oQJeiIbPigJX4QAlgwyy.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xffE8AC09),
                            Color(0xffF87715),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            Assets.images.crown,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            height: 15,
                          ),
                          5.horizontalSpace,
                          const AppText(
                            text: 'Top Rated',
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff020101).withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Column(
                        children: [
                          Text.rich(TextSpan(children: [
                            const WidgetSpan(
                                child: Icon(
                              Iconsax.star1,
                              color: Colors.yellow,
                              size: 18,
                            )),
                            TextSpan(
                              text: '4.0',
                              style: AppTextStyle.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ])),
                          const AppText(
                            text: '2 Reviews',
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                padding: EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppText(
                            text: 'charles meissner',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          AppText(
                            text: 'charles beauty',
                            fontSize: 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          Row(
                            children: [
                              Icon(
                                Iconsax.location,
                                size: 15,
                                color: AppColors.grey3,
                              ),
                              4.horizontalSpace,
                              const AppText(
                                text: '12 mirabi street, festac housing estate',
                                fontSize: 10,
                                color: AppColors.grey3,
                              ),
                            ],
                          ),
                          5.verticalSpace,
                          Wrap(
                            runSpacing: 5,
                            spacing: 5,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.grey1,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                child: const AppText(
                                  text: 'Nail Care',
                                  fontSize: 10,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.grey1,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                child: const AppText(
                                  text: 'Eyebrows & Lashes',
                                  fontSize: 10,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.grey1,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                child: const AppText(
                                  text: 'Locks & Twists',
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Icon(Iconsax.heart),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
