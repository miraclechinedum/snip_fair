import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/buttons.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/gen/assets.gen.dart';

class DefaultStylistCard extends StatelessWidget {
  const DefaultStylistCard({
    required this.seller,
    required this.onLikePressed,
    super.key,
  });

  final SellerDetails seller;
  final Future<bool?> Function() onLikePressed;

  @override
  Widget build(BuildContext context) {
    return AnimationButtonEffect(
      child: GestureDetector(
        onTap: () {
          context.router.push(StylistSellerDetailsRoute(seller: seller));
        },
        child: Container(
          width: double.infinity,
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
                    child: ColoredBox(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: seller.stylistProfile?.banner
                                  ?.completeImagePath() ??
                              '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Assets.images.loading.image(
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (context, url, error) {
                            return ColoredBox(
                              color: Colors.grey.shade200,
                              child: Center(
                                  child: SvgPicture.asset(Assets.images.logo)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          AppText(
                            text: '${seller.distance?.round() ?? 0}Km',
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
                                  text: seller.averageRating?.toString() ?? '0',
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
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12)),
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
                          5.verticalSpace,
                          AppText(
                            text:
                                '${seller.minPrice?.toDouble().formatAmount()} - ${seller.maxPrice?.toDouble().formatAmount()}',
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class LikeItemWidget extends StatefulWidget {
  const LikeItemWidget({
    required this.onLikePressed,
    required this.isLiked,
    super.key,
  });

  final Future<bool?> Function() onLikePressed;
  final bool isLiked;

  @override
  State<LikeItemWidget> createState() => _LikeItemWidgetState();
}

class _LikeItemWidgetState extends State<LikeItemWidget> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final result = await widget.onLikePressed();
        if (result == null) return;
        setState(() {
          isLiked = result;
        });
      },
      icon: Icon(
        isLiked ? Iconsax.heart5 : Iconsax.heart,
        color: isLiked ? Colors.red : AppColors.grey3,
      ),
    );
  }
}
