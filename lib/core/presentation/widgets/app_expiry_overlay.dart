import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget that overlays the entire app after a set number of days,
/// blocking all views with a message on a black background.
class AppExpiryOverlay extends StatelessWidget {
  const AppExpiryOverlay({
    required this.child,
    required this.expiryDate,
    this.title = 'Demo Usage Expired',
    this.message = 'This version of the demo has expired. Please contact app Developer.',
    this.actionButtonText,
    this.onActionPressed,
    super.key,
  });

  /// The child widget (your app)
  final Widget child;

  /// The date when the app should expire
  final DateTime expiryDate;

  /// Title to display on the overlay
  final String title;

  /// Message to display on the overlay
  final String message;

  /// Optional action button text (e.g., "Update Now")
  final String? actionButtonText;

  /// Optional callback when action button is pressed
  final VoidCallback? onActionPressed;

  bool get _isExpired => DateTime.now().isAfter(expiryDate);

  @override
  Widget build(BuildContext context) {
    if (!_isExpired) {
      return child;
    }

    return Stack(
      children: [
        // Original app (disabled)
        IgnorePointer(
          child: child,
        ),
        // Black overlay with message
        ColoredBox(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 80.sp,
                    color: Colors.amber,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16.sp,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (actionButtonText != null && onActionPressed != null) ...[
                    SizedBox(height: 32.h),
                    ElevatedButton(
                      onPressed: onActionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 48.w,
                          vertical: 16.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        actionButtonText!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Text(
                    'Expired on: ${_formatDate(expiryDate)}',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Alternative version that counts days from first app installation
class AppExpiryOverlayWithDaysCount extends StatefulWidget {
  const AppExpiryOverlayWithDaysCount({
    required this.child,
    required this.maxDaysAllowed,
    this.title = 'Trial Period Ended',
    this.message = 'Your trial period has ended. Please upgrade to continue using the app.',
    this.actionButtonText,
    this.onActionPressed,
    super.key,
  });

  /// The child widget (your app)
  final Widget child;

  /// Maximum number of days allowed from first install
  final int maxDaysAllowed;

  /// Title to display on the overlay
  final String title;

  /// Message to display on the overlay
  final String message;

  /// Optional action button text (e.g., "Upgrade Now")
  final String? actionButtonText;

  /// Optional callback when action button is pressed
  final VoidCallback? onActionPressed;

  @override
  State<AppExpiryOverlayWithDaysCount> createState() => _AppExpiryOverlayWithDaysCountState();
}

class _AppExpiryOverlayWithDaysCountState extends State<AppExpiryOverlayWithDaysCount> {
  DateTime? _firstInstallDate;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _checkExpiry();
  }

  Future<void> _checkExpiry() async {
    // TODO: Get first install date from SharedPreferences
    // If not exists, save current date as first install date
    // For now, using a mock implementation

    // Example implementation:
    // final prefs = await SharedPreferences.getInstance();
    // final savedDate = prefs.getString('first_install_date');
    //
    // if (savedDate == null) {
    //   final now = DateTime.now();
    //   await prefs.setString('first_install_date', now.toIso8601String());
    //   _firstInstallDate = now;
    // } else {
    //   _firstInstallDate = DateTime.parse(savedDate);
    // }

    // Mock: assume app was installed 10 days ago
    _firstInstallDate = DateTime.now().subtract(const Duration(days: 10));

    final daysSinceInstall = DateTime.now().difference(_firstInstallDate!).inDays;
    _isExpired = daysSinceInstall >= widget.maxDaysAllowed;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firstInstallDate == null) {
      // Still loading
      return widget.child;
    }

    if (!_isExpired) {
      return widget.child;
    }

    return Stack(
      children: [
        // Original app (disabled)
        IgnorePointer(
          child: widget.child,
        ),
        // Black overlay with message
        ColoredBox(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_clock,
                    size: 80.sp,
                    color: Colors.redAccent,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    widget.message,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16.sp,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.actionButtonText != null && widget.onActionPressed != null) ...[
                    SizedBox(height: 32.h),
                    ElevatedButton(
                      onPressed: widget.onActionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 48.w,
                          vertical: 16.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        widget.actionButtonText!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Text(
                    'Trial expired: ${widget.maxDaysAllowed} days exceeded',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
