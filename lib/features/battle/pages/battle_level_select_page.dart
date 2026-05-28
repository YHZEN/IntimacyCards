import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers.dart';
import '../../../router.dart';
import '../../../services/security_service.dart';
import '../../../shared/widgets/midnight_scaffold.dart';

/// 对战等级选择 · 复用 Lv.4 门禁
class BattleLevelSelectPage extends ConsumerWidget {
  const BattleLevelSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(cardCountsProvider).valueOrNull ?? {};
    final rounds = int.tryParse(
          GoRouterState.of(context).uri.queryParameters['rounds'] ?? '5',
        ) ??
        5;

    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('对战 · 选择氛围', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              '$rounds 回合制 · 赢家抽卡输家执行',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            for (final level in AppConstants.levels)
              _BattleLevelCard(
                level: level,
                count: counts[level.level] ?? 0,
                accent: _levelColor(level.level),
                locked: level.level == 4,
                emptyHint: level.isCustomPool,
                rounds: rounds,
              ).animate().fadeIn(
                    duration: 360.ms,
                    delay: (level.level * 80).ms,
                  ),
          ],
        ),
      ),
    );
  }

  static Color _levelColor(int level) => switch (level) {
        1 => AppColors.level1,
        2 => AppColors.level2,
        3 => AppColors.level3,
        4 => AppColors.level4,
        5 => AppColors.level5,
        _ => AppColors.primary,
      };
}

class _BattleLevelCard extends ConsumerWidget {
  final LevelInfo level;
  final int count;
  final Color accent;
  final bool locked;
  final bool emptyHint;
  final int rounds;

  const _BattleLevelCard({
    required this.level,
    required this.count,
    required this.accent,
    required this.locked,
    required this.rounds,
    this.emptyHint = false,
  });

  Future<void> _onTap(BuildContext context) async {
    HapticFeedback.mediumImpact();

    if (emptyHint && count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('还没有自制卡，先去写一张吧 ✎',
              style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.surfaceAlt,
        ),
      );
      return;
    }

    if (locked) {
      final ok = await _showLv4Gate(context);
      if (!ok) return;
    }
    if (context.mounted) {
      context.push(
        '${Routes.battleFlow}?level=${level.level}&rounds=$rounds',
      );
    }
  }

  Future<bool> _showLv4Gate(BuildContext context) async {
    final security = SecurityService();
    final hasPin = await security.hasLv4Pin();

    if (!hasPin) {
      final controller = TextEditingController();
      bool? agreed = false;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Lv.4 私密大胆 · 18+',
                  style: AppTextStyles.titleMedium),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '此分级包含成人内容。继续意味着双方都已年满 18 周岁且自愿参与。',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: agreed,
                      onChanged: (v) => setState(() => agreed = v),
                      title: Text('我们都已 18 岁且同意',
                          style: AppTextStyles.bodyMedium),
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: AppTextStyles.titleMedium,
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '设置 6 位 Lv.4 密码',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: agreed == true && controller.text.length == 6
                      ? () async {
                          await security.setLv4Pin(controller.text);
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        }
                      : null,
                  child: const Text('解锁'),
                ),
              ],
            );
          });
        },
      );
      return accepted ?? false;
    }

    final inputCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('🔒 输入 Lv.4 密码', style: AppTextStyles.titleMedium),
            content: TextField(
              controller: inputCtl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.titleMedium,
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: inputCtl.text.length == 6
                    ? () async {
                        final verified =
                            await security.verifyLv4Pin(inputCtl.text);
                        if (!ctx.mounted) return;
                        if (verified) {
                          Navigator.pop(ctx, true);
                        } else {
                          setState(() => errorText = '密码不正确');
                          inputCtl.clear();
                        }
                      }
                    : null,
                child: const Text('确认'),
              ),
            ],
          );
        });
      },
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: locked ? AppColors.danger : accent.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(level.symbol,
                  style: AppTextStyles.titleLarge.copyWith(color: accent)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lv.${level.level} ${level.name}',
                        style: AppTextStyles.titleMedium),
                    Text(level.tagline, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Text('$count 张', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
