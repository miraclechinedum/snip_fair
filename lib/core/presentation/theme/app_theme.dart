import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor, primary: AppColors.primaryColor),
        textTheme: GoogleFonts.bioRhymeTextTheme(),
        scaffoldBackgroundColor: AppColors.grey100,
      );
  static ThemeData get darkTheme => ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.bioRhymeTextTheme(),
      );
}
