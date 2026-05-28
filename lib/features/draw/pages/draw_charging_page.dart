import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/midnight_scaffold.dart';
import '../engine/draw_engine.dart';
import '../widgets/card_reveal_sheet.dart';

class DrawChargingPage extends ConsumerStatefulWidget {
  final int level;
  const DrawChargingPage({super.key, required this.level});

  @override
  ConsumerState<DrawChargingPage> createState() => _DrawChargingPageState();
}

class _DrawChargingPageState extends ConsumerState<DrawChargingPage> {
  bool _drawing = false;

  LevelInfo get _level =>
      AppConstants.levels.firstWhere((l) => l.level == widget.level);

  @override
  void initState() {
    super.initState();
    // 进入页面就把 pity 从 settings 加载好，让进度条第一帧后就显示真实值
    final engine = ref.read(drawEngineProvider);
    engine.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _draw({required bool ten}) async {
    if (_drawing) return;
    setState(() => _drawing = true);
    HapticFeedback.heavyImpact();

    final cards = await ref.read(cardRepoProvider).byLevel(widget.level);
    final fns = await ref.read(cardRepoProvider).functionCards();
    final profile = ref.read(coupleProfileProvider).valueOrNull;
    final excluded = profile?.excludedComfortTags ?? const <String>[];

    final engine = ref.read(drawEngineProvider);
    final results = ten
        ? await engine.tenPull(
            level: widget.level,
            levelPool: cards,
            functionPool: fns,
            excludedComfortTags: excluded,
          )
        : [
            await engine.draw(
              level: widget.level,
              levelPool: cards,
              functionPool: fns,
              excludedComfortTags: excluded,
            )
          ];

    if (!mounted) return;

    // 模拟蓄力时长
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardRevealSheet(
        results: results,
        drawLevel: widget.level,
      ),
    );

    if (!mounted) return;
    // 翻牌结束后刷新进度条（pity 在 draw 内已更新）
    setState(() => _drawing = false);
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.read(drawEngineProvider);
    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('Lv.${widget.level} ${_level.name}',
            style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            _suspendedCard(),
            const SizedBox(height: 40),
            _pityIndicator(engine),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GoldButton(
                      label: '单抽',
                      primary: false,
                      onPressed: _drawing ? null : () => _draw(ten: false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GoldButton(
                      label: '十连 ✦ 保底',
                      onPressed: _drawing ? null : () => _draw(ten: true),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _suspendedCard() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 1500.ms).then().fadeOut(duration: 1500.ms),
        Container(
          width: 130,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary, width: 1.5),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1429), Color(0xFF0F0816)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.local_florist,
                color: AppColors.danger, size: 32),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
              begin: -8,
              end: 8,
              duration: 2400.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }

  Widget _pityIndicator(DrawEngine engine) {
    final p = engine.pityCounter / AppConstants.pityThreshold;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          Text(
            '保底进度  ${engine.pityCounter} / ${AppConstants.pityThreshold}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.primary, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: p.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.surface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text('再 ${engine.pityRemaining} 抽必出 SSR',
              style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
