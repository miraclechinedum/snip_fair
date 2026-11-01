import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/core/utils/social_links.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tappable social-media links. Renders nothing when there are none.
class SocialLinksView extends StatelessWidget {
  const SocialLinksView({required this.links, this.title, super.key});

  final List<SocialProfileLink> links;
  final String? title;

  /// Opens a link outside the app (the platform's app or the browser).
  /// Replaceable in tests.
  @visibleForTesting
  static Future<bool> Function(Uri) launcher =
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<void> open(BuildContext context, SocialProfileLink link) async {
    var opened = false;
    try {
      opened = await launcher(link.uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      AppHelper.showSnackBar(
        context,
        message: "We couldn't open ${link.platform}. Please try again later.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          AppText(text: title!, fontWeight: FontWeight.w600),
          8.verticalSpace,
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final link in links)
              Semantics(
                button: true,
                label: 'Open ${link.platform} profile',
                excludeSemantics: true,
                child: Material(
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: AppColors.grey1),
                  ),
                  child: InkWell(
                    key: Key('social_link_${link.uri}'),
                    customBorder: const StadiumBorder(),
                    onTap: () => open(context, link),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              SocialLinks.iconFor(link),
                              size: 20,
                              color: AppColors.primaryColor,
                            ),
                            8.horizontalSpace,
                            AppText(
                              text: link.platform,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
