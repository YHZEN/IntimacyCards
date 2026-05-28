import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 伪 3D 翻牌动画：
///
/// - 用 Y 轴 perspective matrix 旋转 0..π
/// - 在 t==0.5 瞬间切换 [back] / [front] 两个面
/// - 翻面期间附带轻微的 Z 轴上抬 + 高光扫过
///
/// 这不是真正的 3D 模型，但足以在 2D 卡面间制造"翻转"质感，
/// 比单纯淡入淡出在心理上更接近"抽到一张实体卡"。
class CardFlip2D extends StatefulWidget {
  final Widget back;
  final Widget front;
  final Duration duration;

  /// 是否自动播放一次翻转（reveal 场景一般给 true）
  final bool autoplay;

  /// 翻转完成后回调
  final VoidCallback? onFlipped;

  const CardFlip2D({
    super.key,
    required this.back,
    required this.front,
    this.duration = const Duration(milliseconds: 820),
    this.autoplay = true,
    this.onFlipped,
  });

  @override
  State<CardFlip2D> createState() => _CardFlip2DState();
}

class _CardFlip2DState extends State<CardFlip2D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.duration);
    _ctl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFlipped?.call();
      }
    });
    if (widget.autoplay) {
      // 先停一拍再翻，让用户有"准备好"的预期
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _ctl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final t = _ctl.value;
        final angle = t * math.pi;
        final showFront = t > 0.5;

        // 翻面过半时的反向（让正面文字始终正向）
        final displayAngle = showFront ? angle - math.pi : angle;

        // 透视矩阵，制造伪 3D 厚度
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(displayAngle)
          // 翻转过程中略微上抬，离开"卡背原位"
          ..translate(0.0, -math.sin(angle) * 6, 0.0);

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: Stack(
            alignment: Alignment.center,
            children: [
              showFront ? widget.front : widget.back,
              // 翻面途中加一条扫光，强化"翻转中"的视觉信号
              if (t > 0.05 && t < 0.95) _sweepLight(t),
            ],
          ),
        );
      },
    );
  }

  Widget _sweepLight(double t) {
    final intensity = math.sin(t * math.pi); // 0..1..0
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.35 * intensity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.65),
                  Colors.white.withOpacity(0),
                ],
                stops: [
                  (t - 0.25).clamp(0.0, 1.0),
                  t.clamp(0.0, 1.0),
                  (t + 0.25).clamp(0.0, 1.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
