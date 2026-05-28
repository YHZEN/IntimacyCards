import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers.dart';
import '../../router.dart';
import '../../services/security_service.dart';
import '../../shared/widgets/midnight_scaffold.dart';

/// 密码锁 · PRD §5.1
///
/// 首次进入：未设置密码 → 直接跳转到 onboarding（在 onboarding 完成后回来设置密码）
/// 已设置：4 位 PIN 解锁
class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage>
    with TickerProviderStateMixin {
  final _security = SecurityService();
  final _pin = <int>[];
  bool _shake = false;
  String? _hint;
  late final AnimationController _shakeCtl;

  @override
  void initState() {
    super.initState();
    _shakeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _shakeCtl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final hasPin = await _security.hasMainPin();
    final profileExists = await ref.read(coupleRepoProvider).exists();

    if (!mounted) return;

    if (!hasPin || !profileExists) {
      // 首次进入：去 onboarding（onboarding 内会设置密码）
      context.go(Routes.onboarding);
    }
  }

  Future<void> _onDigit(int d) async {
    HapticFeedback.selectionClick();
    if (_pin.length >= 4) return;
    setState(() => _pin.add(d));

    if (_pin.length == 4) {
      final pin = _pin.join();
      final ok = await _security.verifyMainPin(pin);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.mediumImpact();
        context.go(Routes.home);
      } else {
        HapticFeedback.heavyImpact();
        _shakeCtl.forward(from: 0);
        final attempts = await _security.failedAttempts();
        setState(() {
          _pin.clear();
          _hint = '密码错误（连续 $attempts 次）';
        });
      }
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return MidnightScaffold(
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeCtl,
          builder: (_, child) {
            final offset = _shakeOffset(_shakeCtl.value);
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 2),
                          _logo(),
                          const SizedBox(height: 24),
                          Text(
                            '❤  仅你和 TA 知道  ❤',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _pinDots(),
                          if (_hint != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _hint!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.danger),
                            ),
                          ],
                          const Spacer(flex: 1),
                          _keypad(),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _shakeOffset(double t) {
    if (t == 0) return 0;
    return math.sin(t * 8 * 2 * math.pi) * 8 * (1 - t);
  }

  Widget _logo() {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFD9B86E), Color(0xFF8A7340), Color(0xFF1A1320)],
            stops: [0, 0.5, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.favorite, color: AppColors.bg, size: 36),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 2400.ms,
            curve: Curves.easeInOut,
          ),
    );
  }

  Widget _pinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : Colors.transparent,
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.6),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _keypad() {
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) {
      return InkResponse(
        onTap: onTap,
        radius: 48,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: icon != null
                ? Icon(icon, color: AppColors.primary, size: 26)
                : Text(label, style: AppTextStyles.titleLarge),
          ),
        ),
      );
    }

    Widget digit(int d) => key('$d', onTap: () => _onDigit(d));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [digit(1), digit(2), digit(3)],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [digit(4), digit(5), digit(6)],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [digit(7), digit(8), digit(9)],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72),
            digit(0),
            key('', icon: Icons.backspace_outlined, onTap: _backspace),
          ],
        ),
      ],
    );
  }
}
