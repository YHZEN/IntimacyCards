import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/card_rarity.dart';

/// 翻牌瞬间的"稀有度爆发"特效层（不依赖 3D，纯 2D 自绘）：
///
/// - R   ：温柔的淡光晕 + 少量粒子
/// - SR  ：紫色光圈脉冲 + 数条流光 + 中等粒子
/// - SSR ：金色光柱穿过中心 + 旋转光环 + 大量金粒子 + 中心强光
///
/// 用法：盖在卡片上方，宽高填满容器。
class RarityBurst extends StatefulWidget {
  final CardRarity rarity;

  /// 是否让旋转光环和外围粒子持续微动；通常 reveal 进入后保持 true
  final bool persistent;

  const RarityBurst({
    super.key,
    required this.rarity,
    this.persistent = true,
  });

  @override
  State<RarityBurst> createState() => _RarityBurstState();
}

class _RarityBurstState extends State<RarityBurst>
    with TickerProviderStateMixin {
  late final AnimationController _burst;
  late final AnimationController _spin;
  late final List<_Particle> _particles;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    // R 稀有度既没有光柱也没有光环，spin 控制器空转毫无意义 —— 直接不启动
    if (widget.persistent && _needsSpin) _spin.repeat();

    _particles = List.generate(_particleCount, (_) => _spawnParticle());
  }

  bool get _needsSpin =>
      widget.rarity == CardRarity.sr ||
      widget.rarity == CardRarity.ssr ||
      widget.rarity == CardRarity.ur;

  @override
  void dispose() {
    _burst.dispose();
    _spin.dispose();
    super.dispose();
  }

  int get _particleCount => switch (widget.rarity) {
        CardRarity.r => 12,
        CardRarity.sr => 26,
        CardRarity.ssr => 46,
        CardRarity.ur => 60,
      };

  int get _rayCount => switch (widget.rarity) {
        CardRarity.r => 0,
        CardRarity.sr => 4,
        CardRarity.ssr => 8,
        CardRarity.ur => 12,
      };

  _Particle _spawnParticle() {
    final angle = _rng.nextDouble() * math.pi * 2;
    final speed = 0.25 + _rng.nextDouble() * 0.85;
    final lifeOffset = _rng.nextDouble();
    final size = 1.4 + _rng.nextDouble() * 2.8;
    return _Particle(
      angle: angle,
      speed: speed,
      lifeOffset: lifeOffset,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_burst, _spin]),
        builder: (_, __) {
          return CustomPaint(
            painter: _RarityBurstPainter(
              rarity: widget.rarity,
              burstProgress: _burst.value,
              spinProgress: _spin.value,
              particles: _particles,
              rayCount: _rayCount,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double lifeOffset;
  final double size;
  const _Particle({
    required this.angle,
    required this.speed,
    required this.lifeOffset,
    required this.size,
  });
}

class _RarityBurstPainter extends CustomPainter {
  final CardRarity rarity;
  final double burstProgress; // 0..1，一次性
  final double spinProgress; // 0..1 循环
  final List<_Particle> particles;
  final int rayCount;

  _RarityBurstPainter({
    required this.rarity,
    required this.burstProgress,
    required this.spinProgress,
    required this.particles,
    required this.rayCount,
  });

  Color get _baseColor => rarity.color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2.4);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);

    _paintCenterGlow(canvas, center, maxR);
    if (rayCount > 0) _paintRays(canvas, center, maxR);
    if (rarity == CardRarity.ssr || rarity == CardRarity.ur) {
      _paintHalo(canvas, center, maxR);
    }
    _paintParticles(canvas, center, maxR);
  }

  void _paintCenterGlow(Canvas canvas, Offset center, double maxR) {
    // 一次性绽放：0..0.6 快速放大到 60%；0.6..1 缓慢淡出
    final t = burstProgress;
    final scale = t < 0.6 ? Curves.easeOutCubic.transform(t / 0.6) : 1.0;
    final opacity = t < 0.6
        ? 0.55
        : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0) * 0.45;

    final r = (maxR * 0.55) * scale;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _baseColor.withOpacity(opacity),
          _baseColor.withOpacity(opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0, 0.35, 1],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);
  }

  void _paintRays(Canvas canvas, Offset center, double maxR) {
    // 旋转的金/紫光柱：从中心放射，宽度由近向远收窄
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spinProgress * math.pi * 2);

    final length = maxR * 1.1;
    final fade =
        burstProgress < 0.4 ? burstProgress / 0.4 : 1.0; // 入场淡入

    for (int i = 0; i < rayCount; i++) {
      final theta = (i / rayCount) * math.pi * 2;
      canvas.save();
      canvas.rotate(theta);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _baseColor.withOpacity(0.45 * fade),
            _baseColor.withOpacity(0.15 * fade),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, -8, length, 16))
        ..blendMode = BlendMode.plus;
      final path = Path()
        ..moveTo(0, -2)
        ..lineTo(length, -10)
        ..lineTo(length, 10)
        ..lineTo(0, 2)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintHalo(Canvas canvas, Offset center, double maxR) {
    // SSR/UR 专属：环绕的细环 + 内圈描边
    final t = (burstProgress < 0.5 ? burstProgress / 0.5 : 1.0);
    final outerR = maxR * 0.28 * t;
    final innerR = outerR * 0.7;

    final ringPaint = Paint()
      ..color = _baseColor.withOpacity(0.55 * t)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, outerR, ringPaint);

    final innerPaint = Paint()
      ..color = _baseColor.withOpacity(0.35 * t)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, innerR, innerPaint);

    // 沿外环的几个高亮点，随 spinProgress 旋转
    const pointCount = 6;
    for (int i = 0; i < pointCount; i++) {
      final theta =
          (i / pointCount) * math.pi * 2 + spinProgress * math.pi * 2;
      final pos = center +
          Offset(math.cos(theta) * outerR, math.sin(theta) * outerR);
      final dotPaint = Paint()
        ..color = _baseColor.withOpacity(0.85 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(pos, 2.5, dotPaint);
    }
  }

  void _paintParticles(Canvas canvas, Offset center, double maxR) {
    // 粒子从中心向外飞散，受 burstProgress 控制飞行距离
    final t = Curves.easeOutQuad.transform(burstProgress);
    for (final p in particles) {
      // 每个粒子有自己的"起跳时间"，制造错落感
      final local = ((t * 1.4) - p.lifeOffset * 0.4).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final distance = maxR * 0.55 * p.speed * local;
      final pos = center +
          Offset(math.cos(p.angle) * distance, math.sin(p.angle) * distance);
      final alpha = (1 - local).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = _baseColor.withOpacity(alpha * 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
      canvas.drawCircle(pos, p.size * (1 - local * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RarityBurstPainter old) =>
      old.burstProgress != burstProgress ||
      old.spinProgress != spinProgress ||
      old.rarity != rarity;
}
