import 'package:flutter/material.dart';

/// 预设头像 · PRD §5.2
///
/// MVP 阶段使用 Unicode emoji 作为占位，后续替换为 assets/images/avatars/ 下的插画 PNG。
class PresetAvatar {
  final String id;
  final String name;
  final String emoji;
  final Color tint;
  final bool customIcon;

  const PresetAvatar({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tint,
    this.customIcon = false,
  });
}

class Avatars {
  Avatars._();

  static const List<PresetAvatar> all = [
    PresetAvatar(id: 'deer', name: '鹿', emoji: '🦌', tint: Color(0xFFB89968)),
    PresetAvatar(id: 'fox', name: '狐', emoji: '🦊', tint: Color(0xFFD17A4F)),
    PresetAvatar(
      id: 'fish',
      name: '鱼',
      emoji: '🐠',
      tint: Color(0xFF5BA4B8),
      customIcon: true,
    ),
    PresetAvatar(id: 'cat', name: '猫', emoji: '🐱', tint: Color(0xFF9B59B6)),
    PresetAvatar(id: 'rabbit', name: '兔', emoji: '🐰', tint: Color(0xFFE08FA8)),
    PresetAvatar(id: 'dog', name: '犬', emoji: '🐶', tint: Color(0xFFA88848)),
    PresetAvatar(id: 'bear', name: '熊', emoji: '🐻', tint: Color(0xFF8B6F47)),
    PresetAvatar(id: 'wolf', name: '狼', emoji: '🐺', tint: Color(0xFF6E6580)),
    PresetAvatar(id: 'phoenix', name: '凤', emoji: '🦅', tint: Color(0xFFFF1744)),
  ];

  static PresetAvatar byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
