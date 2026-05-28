import 'package:flutter/material.dart';

/// Midnight Ember 配色 · PRD §3.2
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF0E0A14);
  static const Color surface = Color(0xFF1A1320);
  static const Color surfaceAlt = Color(0xFF241828);

  static const Color primary = Color(0xFFC9A961);
  static const Color primaryDim = Color(0xFF8A7340);
  static const Color accent = Color(0xFF8B3A62);
  static const Color accentDeep = Color(0xFF5A2440);

  static const Color textPrimary = Color(0xFFF5E6D3);
  static const Color textSecondary = Color(0xFF9B8B7F);
  static const Color textDim = Color(0xFF5E544A);

  static const Color danger = Color(0xFFFF1744);

  // 稀有度色 · PRD §3.3
  static const Color rarityR = Color(0xFFB8B8B8);
  static const Color raritySR = Color(0xFF9B59B6);
  static const Color raritySSR = Color(0xFFC9A961);
  static const Color rarityUR = Color(0xFFFF1744);

  // 等级色（用于等级选择页）
  static const Color level1 = Color(0xFFE08FA8);
  static const Color level2 = Color(0xFF9B59B6);
  static const Color level3 = Color(0xFF8B3A62);
  static const Color level4 = Color(0xFFFF1744);
  static const Color level5 = Color(0xFFC9A961);

  /// 主背景渐变（顶部更暗，底部偏紫）
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0710), Color(0xFF150E1C), Color(0xFF0A0710)],
    stops: [0.0, 0.5, 1.0],
  );

  /// 暗金按钮渐变
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9B86E), Color(0xFFA88848)],
  );
}
