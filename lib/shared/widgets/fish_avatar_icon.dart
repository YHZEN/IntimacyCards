import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 预设「鱼」头像 · 手绘风格，比 emoji 更统一好看
class FishAvatarIcon extends StatelessWidget {
  final double size;
  final Color tint;

  const FishAvatarIcon({
    super.key,
    required this.size,
    this.tint = const Color(0xFF5BA4B8),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FishPainter(tint: tint),
      ),
    );
  }
}

class _FishPainter extends CustomPainter {
  final Color tint;

  _FishPainter({required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.52;
    final cy = h * 0.5;

    // 柔和水底光晕
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [tint.withOpacity(0.35), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.46));
    canvas.drawCircle(Offset(cx, cy), w * 0.42, glow);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.08);

    // 尾鳍
    final tail = Path()
      ..moveTo(-w * 0.34, 0)
      ..lineTo(-w * 0.48, -h * 0.22)
      ..lineTo(-w * 0.48, h * 0.22)
      ..close();
    final tailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [tint.withOpacity(0.7), tint],
      ).createShader(Rect.fromLTWH(-w * 0.5, -h * 0.25, w * 0.2, h * 0.5));
    canvas.drawPath(tail, tailPaint);

    // 身体
    final bodyRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.52,
      height: h * 0.36,
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(tint, Colors.white, 0.35)!,
          tint,
          Color.lerp(tint, const Color(0xFF8B3A62), 0.25)!,
        ],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // 背鳍
    final dorsal = Path()
      ..moveTo(-w * 0.02, -h * 0.16)
      ..quadraticBezierTo(w * 0.08, -h * 0.28, w * 0.16, -h * 0.14)
      ..quadraticBezierTo(w * 0.06, -h * 0.12, -w * 0.02, -h * 0.16);
    canvas.drawPath(
      dorsal,
      Paint()..color = tint.withOpacity(0.85),
    );

    // 腹鳍
    final belly = Path()
      ..moveTo(w * 0.0, h * 0.12)
      ..quadraticBezierTo(w * 0.1, h * 0.22, w * 0.18, h * 0.1);
    canvas.drawPath(
      belly,
      Paint()..color = tint.withOpacity(0.65),
    );

    // 鳞片高光
    final scalePaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018;
    for (var i = 0; i < 3; i++) {
      final ox = -w * 0.06 + i * w * 0.07;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(ox, 0), width: w * 0.1, height: h * 0.12),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        scalePaint,
      );
    }

    // 眼睛
    final eyeCenter = Offset(w * 0.14, -h * 0.03);
    canvas.drawCircle(eyeCenter, w * 0.055, Paint()..color = Colors.white);
    canvas.drawCircle(
      eyeCenter + Offset(w * 0.012, 0),
      w * 0.028,
      Paint()..color = const Color(0xFF1A1320),
    );
    canvas.drawCircle(
      eyeCenter + Offset(w * 0.02, -w * 0.012),
      w * 0.01,
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    // 腮红
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.06, h * 0.06),
        width: w * 0.08,
        height: h * 0.045,
      ),
      Paint()..color = const Color(0xFFE08FA8).withOpacity(0.35),
    );

    canvas.restore();

    // 小气泡
    final bubble = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    canvas.drawCircle(Offset(w * 0.78, h * 0.28), w * 0.04, bubble);
    canvas.drawCircle(Offset(w * 0.86, h * 0.18), w * 0.025, bubble);
  }

  @override
  bool shouldRepaint(covariant _FishPainter oldDelegate) =>
      oldDelegate.tint != tint;
}
