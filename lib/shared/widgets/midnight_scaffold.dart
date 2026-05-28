import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 全局背景容器：暗紫渐变 + 微粒子 + 角落金色光晕
class MidnightScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;
  final bool showCornerGlow;
  final Widget? drawer;
  final Widget? floatingActionButton;

  const MidnightScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.extendBodyBehindAppBar = true,
    this.showCornerGlow = true,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showCornerGlow) ...[
              _cornerGlow(Alignment.topLeft, AppColors.accent),
              _cornerGlow(Alignment.bottomRight, AppColors.primary),
            ],
            child,
          ],
        ),
      ),
    );
  }

  Widget _cornerGlow(Alignment a, Color color) {
    return Align(
      alignment: a,
      child: IgnorePointer(
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(0.18), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}
