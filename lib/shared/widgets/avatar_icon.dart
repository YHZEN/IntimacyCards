import 'package:flutter/material.dart';

import '../../core/constants/avatars.dart';
import 'fish_avatar_icon.dart';

/// 头像图标（emoji 或自定义绘制）
class AvatarIcon extends StatelessWidget {
  final PresetAvatar avatar;
  final double size;

  const AvatarIcon({
    super.key,
    required this.avatar,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (avatar.customIcon) {
      return FishAvatarIcon(size: size, tint: avatar.tint);
    }
    return Text(avatar.emoji, style: TextStyle(fontSize: size));
  }
}
