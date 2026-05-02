import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/gen/assets.gen.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String updateUrl;
  final String? message;

  const ForceUpdateScreen({Key? key, required this.updateUrl, this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.appgradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        Assets.images.logo,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Update Required',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      message ??
                          'A new version of Snipfair is available. Please update to continue using the app.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withOpacity(0.92),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final fallbackUrl = Platform.isIOS
                              ? 'https://apps.apple.com/ng/app/snipfair/id6755818679'
                              : 'https://play.google.com/store/apps/details?id=com.snipfair.app&hl=uz&pli=1';
                          final url =
                              updateUrl.isNotEmpty ? updateUrl : fallbackUrl;
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Update Now',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Text(
                    //   'Your app will stay secure and up to date with the latest fixes.',
                    //   style: theme.textTheme.bodySmall?.copyWith(
                    //     color: AppColors.white.withOpacity(0.75),
                    //   ),
                    //   textAlign: TextAlign.center,
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
