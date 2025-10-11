import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';

class AppColors {
  const AppColors._();

  //Pyramid Green
  static const primaryColor = Color(0xff9134E9);

  //Icon lemon
  static const iconLemon = Color(0xff66b93b);

  //Background green
  static const backgroundGreen = Color(0xff0d2121);

  static const white = Color(0xffffffff);
  static const whiteShade1 = Color(0xffFDFAF8);
  static const black = Color(0xff000000);
  static const blackShade1 = Color(0xff2B2B29);
  static const transparent = Color(0x00000000);

  //Neutral Colors
  static const grey1 = Color(0xffE4E4E7);
  static const grey2 = Color(0xffA6A6A6);
  static const grey3 = Color(0xff505E6D);
  static const grey4 = Color(0xff535353);
  static const grey5 = Color(0xffDFD9D6);

  // Grey
  static const grey100 = Color(0xffFAFCFE);
  static const darkGrey100 = Color(0xffEFF4FB);
  static const darkGrey300 = Color(0xffC9D4EA);

  static const grey200 = Color(0xffE1E9F8);
  static const grey300 = Color(0xffD1D5DB);
  static const grey400 = Color(0xffB0BBD5);
  static const grey500 = Color(0xff8F9BBA);
  static const grey600 = Color(0xffB7C2D8);
  static const grey700 = Color(0xffB7C2D8);
  static const darkGrey700 = Color(0xff485585);
  static const grey800 = Color(0xff47548C);
  static const grey900 = Color(0xff2B3674);
  static const darkGrey900 = Color(0xff242F5D);
  static const primaryGrey = Color(0xffE0E5F2);

  static const darkTaupe = Color(0xff817B76);

  static const LinearGradient appgradient = LinearGradient(
    colors: [Color(0xff7F80DC), Color(0xffD52A81)],
    stops: [0, 0.5],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> defaultBoxShadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.1),
      spreadRadius: 0,
      blurRadius: 10,
      offset: const Offset(1, 1),
    ),
  ];
  static List<BoxShadow> yellowBoxShadow = [
    BoxShadow(
      color: Colors.amber.withOpacity(0.8),
      spreadRadius: 0,
      blurRadius: 16,
      offset: const Offset(0, -4),
    ),
  ];

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFE80054);
  static const Color contentColorCyan = Color(0xFF50E4FF);

  static const Color success = Color.fromARGB(255, 7, 172, 18);

  static var inputDecoration = InputDecoration(
    hintStyle: AppTextStyle.body1.copyWith(
      color: AppColors.grey2,
    ),

    alignLabelWithHint: true,

    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14).dg,
    // floatingLabelBehavior: FloatingLabelBehavior.always,

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10).r,
      borderSide: BorderSide(color: AppColors.grey2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10).r,
      borderSide: const BorderSide(color: AppColors.contentColorRed),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10).r,
      borderSide: const BorderSide(color: AppColors.primaryColor),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.grey2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10).r,
      borderSide: BorderSide(color: AppColors.grey2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10).r,
      borderSide: BorderSide(color: AppColors.primaryColor),
    ),
  );
}
