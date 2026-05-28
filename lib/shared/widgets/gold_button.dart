import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 暗金主按钮（PRD §3 视觉规范）
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final double? width;

  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon,
              size: 18,
              color: primary ? AppColors.bg : AppColors.primary),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: primary
              ? AppTextStyles.buttonPrimary.copyWith(
                  color: enabled ? AppColors.bg : AppColors.bg.withOpacity(0.6),
                )
              : AppTextStyles.buttonSecondary.copyWith(
                  color: enabled
                      ? AppColors.primary
                      : AppColors.primaryDim,
                ),
        ),
      ],
    );

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          gradient: primary && enabled ? AppColors.goldGradient : null,
          color: primary
              ? (enabled ? null : AppColors.primaryDim.withOpacity(0.3))
              : Colors.transparent,
          border: primary
              ? null
              : Border.all(color: AppColors.primary.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(40),
          boxShadow: primary && enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: content,
      ),
    );
  }
}
