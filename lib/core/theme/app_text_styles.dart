import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 字体规范 · PRD §3.4
class AppTextStyles {
  AppTextStyles._();

  /// 衬线标题字体（思源宋体），用于标题、卡名、稀有度
  static TextStyle serif({
    double size = 18,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.notoSerifSc(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// 无衬线正文（苹方/Inter 风），用于描述、按钮
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle get displayLarge => serif(size: 32, weight: FontWeight.w600, letterSpacing: 4);
  static TextStyle get titleLarge => serif(size: 24, weight: FontWeight.w500, letterSpacing: 2);
  static TextStyle get titleMedium => serif(size: 18, weight: FontWeight.w500, letterSpacing: 1);
  static TextStyle get titleSmall => serif(size: 14, weight: FontWeight.w500, letterSpacing: 0.5);

  static TextStyle get bodyLarge => sans(size: 16, height: 1.6);
  static TextStyle get bodyMedium => sans(size: 14, height: 1.5);
  static TextStyle get bodySmall => sans(size: 12, color: AppColors.textSecondary, height: 1.4);

  static TextStyle get caption => sans(size: 11, color: AppColors.textSecondary, letterSpacing: 1);

  static TextStyle get buttonPrimary =>
      serif(size: 16, weight: FontWeight.w600, color: AppColors.bg, letterSpacing: 2);

  static TextStyle get buttonSecondary =>
      sans(size: 14, weight: FontWeight.w500, color: AppColors.primary, letterSpacing: 1);
}
