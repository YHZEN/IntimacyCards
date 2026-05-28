import 'package:flutter/material.dart';

import '../../core/constants/avatars.dart';
import '../../core/theme/app_colors.dart';
import 'avatar_icon.dart';

class AvatarBadge extends StatelessWidget {
  final PresetAvatar avatar;
  final double size;
  final bool highlighted;
  final VoidCallback? onTap;

  const AvatarBadge({
    super.key,
    required this.avatar,
    this.size = 64,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(
            color: highlighted ? AppColors.primary : AppColors.primaryDim,
            width: highlighted ? 2.5 : 1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: AvatarIcon(avatar: avatar, size: size * (avatar.customIcon ? 0.72 : 0.55)),
      ),
    );
  }
}
