import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_colors.dart';

/// 主页中央悬浮的卡背
///
/// 用多频率 sin/cos 叠加模拟「水中飘浮」——周期互不整除、无折返拐点。
class CardBack3D extends StatefulWidget {
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
  State<CardBack3D> createState() => _CardBack3DState();
}

class _CardBack3DState extends State<CardBack3D> {
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  late DateTime _lastFrame;

  /// 相位基准周期（秒）——越短整体节奏越快
  static const _cycleSec = 17.0;

  @override
  void initState() {
    super.initState();
    _lastFrame = DateTime.now();
    _ticker = Ticker((_) {
      final now = DateTime.now();
      _elapsed += now.difference(_lastFrame);
      _lastFrame = now;
      setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  double get _t => _elapsed.inMicroseconds / 1e6 / _cycleSec * 2 * pi;

  _FloatPose _pose() {
    final t = _t;
    // 幅度更大、频率略高，轨迹更「活」
    final dx = 10.0 * sin(t * 0.78 + 0.9) + 4.0 * sin(t * 1.28 + 2.1);
    final dy = 16.0 * sin(t * 0.62) + 7.0 * sin(t * 1.05 + 1.4);
    final rotY = 0.30 * sin(t * 0.58 + 0.6) + 0.11 * sin(t * 0.92 + 1.9);
    final rotZ = 0.065 * sin(t * 0.72 + 2.4);
    final halo = 0.52 + 0.48 * sin(t * 0.48 + 0.3);
    return _FloatPose(dx: dx, dy: dy, rotY: rotY, rotZ: rotZ, halo: halo);
  }

  @override
  Widget build(BuildContext context) {
    final pose = _pose();

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: pose.halo.clamp(0.0, 1.0),
            child: _Halo(width: widget.width, height: widget.height),
          ),
          Transform.translate(
            offset: Offset(pose.dx, pose.dy),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(pose.rotY)
                ..rotateZ(pose.rotZ),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: _CardFace(shadowLift: pose.dy),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatPose {
  final double dx;
  final double dy;
  final double rotY;
  final double rotZ;
  final double halo;

  const _FloatPose({
    required this.dx,
    required this.dy,
    required this.rotY,
    required this.rotZ,
    required this.halo,
  });
}

class _Halo extends StatelessWidget {
  final double width;
  final double height;

  const _Halo({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
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
    );
  }
}

class _CardFace extends StatelessWidget {
  final double shadowLift;

  const _CardFace({this.shadowLift = 0});

  @override
  Widget build(BuildContext context) {
    // 随上浮略微减弱阴影，模拟离光更近
    final lift = (1 - (shadowLift + 18) / 36).clamp(0.55, 1.0);

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
            color: AppColors.primary.withOpacity(0.35 * lift),
            blurRadius: 32,
            spreadRadius: 1,
            offset: Offset(0, 5 - shadowLift * 0.22),
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.2 * lift),
            blurRadius: 60,
            spreadRadius: 8,
            offset: Offset(0, 10 - shadowLift * 0.28),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: CustomPaint(
              size: Size.infinite,
              painter: _CornerOrnamentPainter(),
            ),
          ),
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
                  color: AppColors.danger.withOpacity(0.5 * lift),
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

    final midPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(size.width / 2, 0), 2, midPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height), 2, midPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
