import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// 主页中央悬浮的卡背
///
/// MVP 阶段用 Flutter 原生绘制 + Y 轴慢速旋转模拟"3D 自转"。
/// 后续可替换为 Rive 动画文件以获得更精致的效果。
class CardBack3D extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback? onTap;

  const CardBack3D({
    super.key,
    this.width = 200,
    this.height = 280,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _halo(),
          _floatingCard(),
        ],
      ),
    );
  }

  Widget _halo() {
    return Container(
      width: width * 2,
      height: height * 1.6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withOpacity(0.25),
            AppColors.accent.withOpacity(0.06),
            Colors.transparent,
          ],
          stops: const [0, 0.35, 1],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
          begin: 0.6,
          duration: 3000.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _floatingCard() {
    return SizedBox(
      width: width,
      height: height,
      child: const _CardFace(),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -6, end: 6, duration: 3200.ms, curve: Curves.easeInOut)
        .then()
        .animate(onPlay: (c) => c.repeat())
        .custom(
          duration: 12000.ms,
          builder: (_, value, child) => Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(value * 0.4 - 0.2),
            alignment: Alignment.center,
            child: child,
          ),
          end: 1,
        );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1429), Color(0xFF0F0816), Color(0xFF1E1429)],
        ),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 32,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.2),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 卡面边框花纹（用 CustomPaint 画一个简单的金色四角）
          Padding(
            padding: const EdgeInsets.all(12),
            child: CustomPaint(
              size: Size.infinite,
              painter: _CornerOrnamentPainter(),
            ),
          ),
          // 中央玫瑰
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.danger.withOpacity(0.85),
                  AppColors.accentDeep,
                  Colors.transparent,
                ],
                stops: const [0, 0.5, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.5),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.local_florist,
                  color: AppColors.textPrimary, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const corner = 24.0;
    // 四角金线 L 型
    for (final dx in [0.0, size.width]) {
      for (final dy in [0.0, size.height]) {
        final path = Path();
        final hx = dx == 0 ? corner : -corner;
        final hy = dy == 0 ? corner : -corner;
        path.moveTo(dx, dy + hy);
        path.lineTo(dx, dy);
        path.lineTo(dx + hx, dy);
        canvas.drawPath(path, paint);
      }
    }

    // 顶部和底部中间的小装饰
    final midPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(size.width / 2, 0), 2, midPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height), 2, midPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
