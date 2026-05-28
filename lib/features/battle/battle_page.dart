import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../router.dart';
import '../../shared/widgets/gold_button.dart';
import '../../shared/widgets/midnight_scaffold.dart';

/// 对战模式大厅 · 选择回合数后进入等级选择
class BattlePage extends ConsumerStatefulWidget {
  const BattlePage({super.key});

  @override
  ConsumerState<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends ConsumerState<BattlePage> {
  int _rounds = 5;

  static const _roundOptions = [3, 5, 7];

  @override
  Widget build(BuildContext context) {
    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('对战模式', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.sports_kabaddi,
                      size: 72, color: AppColors.primary)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 2000.ms,
                  ),
              const SizedBox(height: 24),
              Text('双人对决', style: AppTextStyles.displayLarge.copyWith(fontSize: 32))
                  .animate()
                  .fadeIn(duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                '小游戏定胜负 · 赢家抽卡 · 输家执行',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(letterSpacing: 2),
              ),
              const Spacer(),
              Text('回合数', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final n in _roundOptions) ...[
                    _roundChip(n),
                    if (n != _roundOptions.last) const SizedBox(width: 12),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'R +10 · SR +30 · SSR +80 分',
                style: AppTextStyles.caption,
              ),
              const Spacer(flex: 2),
              GoldButton(
                label: '选择等级',
                icon: Icons.play_arrow_rounded,
                width: double.infinity,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push('${Routes.battleLevel}?rounds=$_rounds');
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundChip(int n) {
    final selected = _rounds == n;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _rounds = n);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.primaryDim,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Text(
          '$n 局',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
