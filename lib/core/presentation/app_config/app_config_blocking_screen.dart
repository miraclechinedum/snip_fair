import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snip_fair/core/data/models/remote/app_config.dart';
import 'package:snip_fair/core/presentation/app_config/app_config_controller.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/gen/assets.gen.dart';

class AppConfigBlockingScreen extends StatelessWidget {
  const AppConfigBlockingScreen({
    required this.config,
    required this.reason,
    required this.isRetrying,
    required this.onRetry,
    super.key,
  });

  final AppConfig config;
  final AppBlockReason reason;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (reason) {
      AppBlockReason.shutdown => 'Snipfair is unavailable',
      AppBlockReason.maintenance => 'Maintenance in progress',
      AppBlockReason.versionBlocked => 'Update required',
    };
    final message = reason == AppBlockReason.versionBlocked
        ? 'This app version is no longer supported. Please update Snipfair to continue.'
        : config.maintenanceMessage;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.grey100,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.defaultBoxShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            gradient: AppColors.appgradient,
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            Assets.images.logo,
                            width: 72,
                            height: 72,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.blackShade1,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey3,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isRetrying ? null : onRetry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor:
                                  AppColors.primaryColor.withOpacity(0.45),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isRetrying
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
