import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:snip_fair/gen/assets.gen.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/features/explore/widgets/default_stylist_card.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/animation_button_effect.dart';

class TopStylistCard extends StatelessWidget {
  const TopStylistCard({
    required this.seller,
    required this.onLikePressed,
    super.key,
    this.isTopRated = false,
  });

  final SellerDetails seller;
  final bool isTopRated;
  final Future<bool?> Function() onLikePressed;

  @override
  Widget build(BuildContext context) {
    return AnimationButtonEffect(
      child: GestureDetector(
        onTap: () {
          context.router.push(StylistSellerDetailsRoute(seller: seller));
        },
        child: AnimationButtonEffect(
          child: Container(
            width: 300.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 150.h,
                      width: double.infinity,
                      child: ColoredBox(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: seller.stylistProfile?.banner?.completeImagePath() ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Assets.images.loading.image(
                              fit: BoxFit.cover,
                            ),
                            errorWidget: (context, url, error) {
                              return ColoredBox(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: SvgPicture.asset(Assets.images.logo),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (isTopRated)
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
                            Text.rich(
                              TextSpan(
                                children: [
                                  const WidgetSpan(
                                    child: Icon(
                                      Iconsax.star1,
                                      color: Colors.yellow,
                                      size: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text: seller.averageRating?.toString(),
                                    style: AppTextStyle.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppText(
                              text: '${seller.reviewsCount ?? 0} Reviews',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppText(
                                text: seller.name ?? 'N/A',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              AppText(
                                text: seller.stylistProfile?.businessName ?? 'N/A',
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Iconsax.location,
                                    size: 15,
                                    color: AppColors.grey3,
                                  ),
                                  4.horizontalSpace,
                                  Expanded(
                                    child: AppText(
                                      text: seller.country ?? 'N/A',
                                      fontSize: 10,
                                      color: AppColors.grey3,
                                    ),
                                  ),
                                ],
                              ),
                              5.verticalSpace,
                              // Wrap(
                              //     runSpacing: 5,
                              //     spacing: 5,
                              //     children: List.generate(
                              //         seller.stylistProfile?.works?.length ?? 0,
                              //         (index) {
                              //       final work =
                              //           seller.stylistProfile!.works![index];
                              //       return Container(
                              //         decoration: BoxDecoration(
                              //           color: AppColors.grey1,
                              //           borderRadius: BorderRadius.circular(24),
                              //         ),
                              //         padding: const EdgeInsets.symmetric(
                              //           horizontal: 12,
                              //           vertical: 3,
                              //         ),
                              //         child: AppText(
                              //           text: work,
                              //           fontSize: 10,
                              //         ),
                              //       );
                              //     }))
                            ],
                          ),
                        ),
                        LikeItemWidget(
                          onLikePressed: onLikePressed,
                          isLiked: seller.favourite ?? false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
