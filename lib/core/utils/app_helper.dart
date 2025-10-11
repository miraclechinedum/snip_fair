// ignore_for_file: only_throw_errors, join_return_with_assignment

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:snip_fair/core/data/models/remote/platform_settings.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/profile_completeness.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../presentation/theme/theme.dart';

class AppHelper {
  AppHelper._();

  static showAppModal(BuildContext context, Widget widget,
      [Color? backgroundColor]) {
    showModalBottomSheet(
        context: context,
        backgroundColor: backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        builder: (context) => widget);
  }

  static Future<T?> showAppDialog<T>(
    BuildContext context,
    Widget widget, {
    double height = 387,
    double width = 335,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      barrierColor: AppColors.black.withOpacity(0.8),
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16)),
          height: height,
          width: width,
          child: Builder(
            builder: (context) {
              return widget;
            },
          ),
        ),
      ),
    );
  }

  static void showSnackBar(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Text(
        message,
        style: AppTextStyle.body2.copyWith(color: const Color(0xffDFBF50)),
      ),
      // action: SnackBarAction(
      //   label: 'Close',
      //   disabledTextColor: AppColors.black,
      //   textColor: AppColors.black,
      //   onPressed: () {
      //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
      //   },
      // ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(
      ClipboardData(
        text: value,
      ),
    ).then((_) {
      showSnackBar(context, message: 'Copied to clipboard');
    });
  }

  static void showNoConnectionSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(
      backgroundColor: const Color.fromARGB(255, 99, 240, 104),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Text(
        'No internet connection',
        style: AppTextStyle.body2.copyWith(color: Colors.white),
      ),
      action: SnackBarAction(
        label: 'Close',
        disabledTextColor: AppColors.black,
        textColor: AppColors.black,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Future<T?> showCustomModalBottomSheet<T>({
    required BuildContext context,
    required Widget modal,
    required bool isDarkMode,
    double radius = 12,
    bool isDrag = true,
    bool isDismissible = true,
    double paddingTop = 100,
  }) {
    return showModalBottomSheet<T>(
      isDismissible: isDismissible,
      enableDrag: isDrag,
      useRootNavigator: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - paddingTop,
      ),
      backgroundColor: Colors.white,
      context: context,
      builder: (context) => modal,
    );
  }

  static void showAlertDialog({
    required BuildContext context,
    required Widget child,
    double radius = 16,
  }) {
    final alert = AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(radius),
        ),
      ),
      contentPadding: const EdgeInsets.all(20),
      iconPadding: EdgeInsets.zero,
      content: child,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static String? getAppName() {
    return 'iStudy';
  }

  static RegExp get getPhoneNumberRegex =>
      RegExp(r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,8}\$');

  static RegExp get getBillNumberRegex => RegExp(r'(^(?:[+0]9)?[0-9]{5,19}$)');

  static RegExp get getBetNumberRegex => RegExp(r'(^(?:[+0]9)?[0-9]{8,10}$)');

  static Future<void> launchHttp(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView)) {
      throw 'Could not launch $url';
    }
  }

  static Future<void> sendMail(String address) async {
    if (!await launchUrl(Uri.parse('mailto:$address'))) {
      throw 'Could not launch $address';
    }
  }

  static String cleanAmountString(String value) {
    // check for comma as decimal separator
    final regExp = RegExp(r',[\d]{1,2}$');
    var newValue = value;
    if (regExp.hasMatch(value)) {
      newValue = value.replaceAll('.', '');
      newValue = value.replaceAll(',', '.');
    }

    newValue = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return newValue;
  }

  static double? parseDouble(String value, {bool zeroIsNull = false}) {
    // check for comma as decimal separator
    final regExp = RegExp(r',[\d]{1,2}$');
    var newValue = value;
    if (regExp.hasMatch(value)) {
      newValue = value.replaceAll('.', '');
      newValue = value.replaceAll(',', '.');
    }

    newValue = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');

    final doubleValue = double.tryParse(newValue) ?? 0.0;

    return (doubleValue == 0 && zeroIsNull) ? null : doubleValue;
  }

  static double getHeightPagePercentage(BuildContext context, double value) {
    return MediaQuery.of(context).size.height * value;
  }

  static double getWidthPercentage(BuildContext context, double value) {
    return MediaQuery.of(context).size.height * value;
  }

  static Future<BaseDeviceInfo> getDeviceInfo() async {
    if (Platform.isAndroid) {
      return DeviceInfoPlugin().androidInfo;
    } else if (Platform.isIOS) {
      return DeviceInfoPlugin().iosInfo;
    } else {
      throw UnimplementedError();
    }
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 18) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  static int profilePercentCompletion(ProfileCompleteness profileCompleteness) {
    int percent = 0;
    if (profileCompleteness.paymentMethod ?? false) {
      percent += 10;
    }
    if (profileCompleteness.statusApproved ?? false) {
      percent += 10;
    }
    if (profileCompleteness.locationService != null) {
      percent += 10;
    }
    if (profileCompleteness.address ?? false) {
      percent += 10;
    }
    // if (profileCompleteness.subscriptionStatus ?? false) {
    //   percent += 10;
    // }
    if (profileCompleteness.socialLinks ?? false) {
      percent += 10;
    }
    if (profileCompleteness.works ?? false) {
      percent += 10;
    }
    if (profileCompleteness.userAvatar ?? false) {
      percent += 10;
    }
    if (profileCompleteness.userBio ?? false) {
      percent += 10;
    }
    if (profileCompleteness.portfolio ?? false) {
      percent += 10;
    }
    if (profileCompleteness.userBanner ?? false) {
      percent += 10;
    }
    return percent;
  }

  static bool isStylistProfileComplete(
      ProfileCompleteness profileCompleteness) {
    return profilePercentCompletion(profileCompleteness) == 100;
  }

  static bool isStylist(BuildContext context) {
    final user = context.read<AppCubit>().state;
    return user.isStylist;
  }

  static String initialsFromName(String firstName, String lastName) {
    return (firstName.isNotEmpty ? firstName[0] : '') +
        (lastName.isNotEmpty ? lastName[0] : '');
  }

  static void unfocus(BuildContext context) =>
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();

  static PlatformSettings appSettings(BuildContext context) {
    return context.read<AppCubit>().state.platformSettings ??
        PlatformSettings();
  }
}
