import 'package:flutter/material.dart';
import 'package:snip_fair/core/data/models/remote/app_config.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/app_config/app_config_blocking_screen.dart';
import 'package:snip_fair/core/presentation/app_config/app_config_controller.dart';

class AppStateGuard extends StatefulWidget {
  const AppStateGuard({required this.child, super.key});

  final Widget child;

  @override
  State<AppStateGuard> createState() => _AppStateGuardState();
}

class _AppStateGuardState extends State<AppStateGuard>
    with WidgetsBindingObserver {
  late final AppConfigController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<AppConfigController>();
    WidgetsBinding.instance.addObserver(this);

    if (_controller.config == null) {
      _controller.refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final reason = _controller.blockReason;
        final config = _controller.config ?? AppConfig.defaults();

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (reason != null)
              Positioned.fill(
                child: AppConfigBlockingScreen(
                  config: config,
                  reason: reason,
                  isRetrying: _controller.isRefreshing,
                  onRetry: _controller.refresh,
                ),
              ),
          ],
        );
      },
    );
  }
}
