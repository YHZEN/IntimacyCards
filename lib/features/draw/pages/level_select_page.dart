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

class LevelSelectPage extends ConsumerWidget {
  const LevelSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(cardCountsProvider).valueOrNull ?? {};

    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('选择今晚的氛围', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            for (final level in AppConstants.levels)
              _LevelCard(
                level: level,
                count: counts[level.level] ?? 0,
                accent: _levelColor(level.level),
                locked: level.level == 4,
              ).animate().fadeIn(
                    duration: 360.ms,
                    delay: (level.level * 80).ms,
                  ).slideY(begin: 0.1, end: 0),
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
        _ => AppColors.primary,
      };
}

class _LevelCard extends ConsumerWidget {
  final LevelInfo level;
  final int count;
  final Color accent;
  final bool locked;

  const _LevelCard({
    required this.level,
    required this.count,
    required this.accent,
    required this.locked,
  });

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();

    if (locked) {
      final ok = await _showLv4Gate(context);
      if (!ok) return;
    }
    if (context.mounted) {
      context.push('${Routes.drawCharging}?level=${level.level}');
    }
  }

  Future<bool> _showLv4Gate(BuildContext context) async {
    final security = SecurityService();
    final hasPin = await security.hasLv4Pin();

    if (!hasPin) {
      // 首次进入：弹同意书 + 设置密码
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
                      '此分级包含成人内容。继续意味着双方：\n'
                      '· 都已年满 18 周岁\n'
                      '· 自愿参与，可随时说出"安全词"暂停\n'
                      '· 同意以下卡片可能涉及性内容\n',
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
                    const SizedBox(height: 4),
                    Text('设置 6 位独立密码（建议与主密码不同）',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: AppTextStyles.titleMedium,
                      cursorColor: AppColors.primary,
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('取消',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: agreed == true && controller.text.length == 6
                      ? () async {
                          await security.setLv4Pin(controller.text);
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        }
                      : null,
                  child: Text('解锁',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            );
          });
        },
      );
      return accepted ?? false;
    }

    // 已设置密码：弹密码验证
    final inputCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('🔒 输入 Lv.4 密码',
                style: AppTextStyles.titleMedium),
            content: TextField(
              controller: inputCtl,
              onChanged: (_) => setState(() => errorText = null),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              autofocus: true,
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
                child: Text('取消',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: inputCtl.text.length == 6
                    ? () async {
                        final ok = await security.verifyLv4Pin(inputCtl.text);
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.pop(ctx, true);
                        } else {
                          setState(() => errorText = '密码不正确');
                          inputCtl.clear();
                        }
                      }
                    : null,
                child: Text('确认',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary)),
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
        onTap: () => _onTap(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: locked ? AppColors.danger : accent.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(level.symbol,
                    style: AppTextStyles.titleLarge.copyWith(color: accent)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Lv.${level.level} ',
                            style: AppTextStyles.titleMedium
                                .copyWith(color: accent)),
                        Text(level.name,
                            style: AppTextStyles.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(level.tagline, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (locked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('需密码',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.danger)),
                    )
                  else
                    Text('$count 张',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right,
                      color: accent.withOpacity(0.7), size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
