import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark palette (Default)
  static const Color darkBg1 = Color(0xFF07070A);
  static const Color darkBg2 = Color(0xFF0E0E14);
  static const Color darkInk = Color(0xFFF5F5F7);
  static const Color darkMute = Color(0x8CF5F5F7);
  static const Color darkGlass = Color(0x801C1C22);
  static const Color darkBorder = Color(0x17FFFFFF);
  static const Color darkHighlight = Color(0x24FFFFFF);
  static const Color darkAccent = Color(0xFFD4FF8A);
  static const Color darkAccentDeep = Color(0xFF9DFF4A);
  static const Color darkAccentInk = Color(0xFF0A0A0C);
  static const Color darkBlob1 = Color(0xFF2A3A1C);
  static const Color darkBlob2 = Color(0xFF1C2A3A);

  // Light palette
  static const Color lightBg1 = Color(0xFFF3F4F1);
  static const Color lightBg2 = Color(0xFFFFFFFF);
  static const Color lightInk = Color(0xFF0A0A0C);
  static const Color lightMute = Color(0x800A0A0C);
  static const Color lightGlass = Color(0x8CFFFFFF);
  static const Color lightBorder = Color(0xB3FFFFFF);
  static const Color lightHighlight = Color(0xE6FFFFFF);
  static const Color lightAccent = Color(0xFF7FD12E);
  static const Color lightAccentDeep = Color(0xFF6FCF2E);
  static const Color lightAccentInk = Color(0xFFFFFFFF);
  static const Color lightBlob1 = Color(0xFFEAFFD0);
  static const Color lightBlob2 = Color(0xFFD9ECFF);
}

class AppTheme {
  static ThemeData getTheme({required bool isDark}) {
    final bg1 = isDark ? AppColors.darkBg1 : AppColors.lightBg1;
    final bg2 = isDark ? AppColors.darkBg2 : AppColors.lightBg2;
    final ink = isDark ? AppColors.darkInk : AppColors.lightInk;
    final acc = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: acc,
      textTheme: GoogleFonts.interTightTextTheme().apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: acc,
        onPrimary: isDark ? AppColors.darkAccentInk : AppColors.lightAccentInk,
        secondary: isDark ? AppColors.darkAccentDeep : AppColors.lightAccentDeep,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: bg2,
        onSurface: ink,
      ),
    );
  }
}

class GlassBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isDark;
  final VoidCallback? onTap;

  const GlassBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.isDark = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glassColor = isDark ? AppColors.darkGlass : AppColors.lightGlass;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final highlightColor = isDark ? AppColors.darkHighlight : AppColors.lightHighlight;

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: highlightColor,
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: content,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
