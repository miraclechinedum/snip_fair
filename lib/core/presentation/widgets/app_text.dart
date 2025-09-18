import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';

class AppText extends StatelessWidget {
  const AppText({
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w400,
    this.textAlign = TextAlign.left,
    required this.text,
    this.textTheme,
    this.overflow,
    this.letterSpacing = 1,
    this.maxLines,
    this.color,
    this.height,
    this.decoration,
  });
  final double fontSize;
  final FontWeight? fontWeight;
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final TextTheme? textTheme;
  final double? letterSpacing;
  final double? height;
  final int? maxLines;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: overflow,
      textAlign: textAlign,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        color: color ?? Colors.grey.shade700,
        fontSize: fontSize.sp,
        fontWeight: fontWeight,
        height: height?.h,
        decoration: decoration,
        // letterSpacing: letterSpacing,
        textStyle: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
