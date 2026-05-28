import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/card_rarity.dart';
import '../../../data/models/diary_entry.dart';
import '../../../providers.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../diary/widgets/diary_capture_sheet.dart';
import '../engine/draw_engine.dart';
import '../engine/function_card_handler.dart';
import 'card_flip_2d.dart';
import 'rarity_burst.dart';

/// 对战模式翻牌上下文
class BattleRevealContext {
  final String winnerName;
  final String loserName;
  final void Function({required bool completed, required int roundScore})
      onFinished;

  const BattleRevealContext({
    required this.winnerName,
    required this.loserName,
    required this.onFinished,
  });
}

/// 翻牌底部弹层：支持单张 / 十连
///
/// 视觉构成：
/// - 背景：按稀有度径向渐变
/// - 中央层：`RarityBurst` 粒子 / 光柱 / 光环（R/SR/SSR 强度递增）
/// - 卡片：`CardFlip2D` 伪翻牌进入；翻面后 shimmer + 边框流光
/// - 底部：接受 / 跳过；功能卡为 丢弃 / 使用
class CardRevealSheet extends ConsumerStatefulWidget {
  final List<DrawResult> results;
  final int drawLevel;
  final BattleRevealContext? battleContext;

  const CardRevealSheet({
    super.key,
    required this.results,
    required this.drawLevel,
    this.battleContext,
  });

  @override
  ConsumerState<CardRevealSheet> createState() => _CardRevealSheetState();
}

class _CardRevealSheetState extends ConsumerState<CardRevealSheet> {
  late List<DrawResult> _results;
  int _index = 0;
  bool _flipped = false;
  bool _processing = false;

  DrawResult get _current => _results[_index];

  @override
  void initState() {
    super.initState();
    _results = List.of(widget.results);
  }

  void _gotoNext() {
    if (_index < _results.length - 1) {
      setState(() {
        _index++;
        _flipped = false; // 下一张重新翻
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // ----------------------------- 任务卡：接受 -----------------------------

  String _executorNameFor(DrawResult result) {
    final battle = widget.battleContext;
    if (battle == null) {
      return ref.read(coupleProfileProvider).valueOrNull?.activeName ?? '';
    }
    return switch (result.effectiveExecutor) {
      CardExecutor.loser => battle.loserName,
      CardExecutor.winner => battle.winnerName,
      CardExecutor.both => '${battle.winnerName} & ${battle.loserName}',
    };
  }

  String? _executorLabelFor(DrawResult result) {
    final battle = widget.battleContext;
    if (battle == null) {
      final profile = ref.read(coupleProfileProvider).valueOrNull;
      if (profile == null || result.taskCard == null) return null;
      return switch (result.effectiveExecutor) {
        CardExecutor.loser => '由 ${profile.activeName} 完成',
        CardExecutor.winner => '由 ${profile.inactiveName} 完成',
        CardExecutor.both => '两人一起完成',
      };
    }
    if (result.taskCard == null) return null;
    return switch (result.effectiveExecutor) {
      CardExecutor.loser => '由 ${battle.loserName} 完成',
      CardExecutor.winner => '由 ${battle.winnerName} 完成',
      CardExecutor.both => '两人一起完成',
    };
  }

  Future<void> _accept() async {
    if (_processing) return;
    HapticFeedback.mediumImpact();
    final result = _current;
    if (!result.isTask) return;

    setState(() => _processing = true);
    final card = result.taskCard!;
    final executorName = _executorNameFor(result);
    final isBattle = widget.battleContext != null;

    await ref.read(drawRepoProvider).insert(
          cardId: card.id,
          isCompleted: true,
          isSkipped: false,
          isBattle: isBattle,
          executorName: executorName,
        );
    final reward = card.rarity.score * result.rewardMultiplier;
    await ref.read(coupleProfileProvider.notifier).addIntimacyExp(reward);
    ref.invalidate(collectedCardIdsProvider);

    if (!mounted) {
      return;
    }

    if (isBattle) {
      widget.battleContext!.onFinished(
        completed: true,
        roundScore: card.rarity.score * result.rewardMultiplier,
      );
      if (!mounted) return;
      setState(() => _processing = false);
      _gotoNext();
      return;
    }

    final captured = await DiaryCaptureSheet.show(
      context,
      cardTitle: card.title,
      accentColor: card.rarity.color,
    );

    if (captured != null) {
      final note = StringBuffer(captured.content);
      if (result.customWishText != null && result.customWishText!.isNotEmpty) {
        if (note.isNotEmpty) note.write('\n\n');
        note.write('（心愿：${result.customWishText}）');
      }
      await ref.read(diaryRepoProvider).insert(
            DiaryEntry(
              cardId: card.id,
              mood: captured.mood,
              content: note.toString(),
              createdAt: DateTime.now(),
              executorName: executorName,
            ),
          );
      ref.invalidate(diaryCountProvider);
      ref.invalidate(diaryEntriesProvider);
    }

    if (!mounted) return;
    setState(() => _processing = false);
    _gotoNext();
  }

  Future<void> _skip() async {
    if (_processing) return;
    HapticFeedback.lightImpact();
    final isBattle = widget.battleContext != null;
    if (_current.isTask) {
      await ref.read(drawRepoProvider).insert(
            cardId: _current.taskCard!.id,
            isCompleted: false,
            isSkipped: true,
            isBattle: isBattle,
            executorName: _executorNameFor(_current),
          );
    }
    if (isBattle) {
      widget.battleContext!.onFinished(completed: false, roundScore: 0);
    }
    _gotoNext();
  }

  // ----------------------------- 功能卡：使用 / 丢弃 -----------------------------

  Future<void> _useFunctionCard() async {
    if (_processing) return;
    final fn = _current.functionCard;
    if (fn == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _processing = true);

    final handler = FunctionCardHandler(ref);
    final outcome = await handler.apply(
      fn: fn,
      drawLevel: widget.drawLevel,
      context: context,
    );

    if (!mounted) return;
    setState(() => _processing = false);

    if (outcome.notice != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(outcome.notice!, style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.surfaceAlt,
          duration: const Duration(milliseconds: 1400),
        ),
      );
    }

    if (outcome.cancelled) return; // 保持当前位置，让用户重新决定

    if (outcome.replaceWith != null) {
      // 把功能卡换成它产出的任务卡（同位置），并重置翻牌动画
      setState(() {
        _results[_index] = outcome.replaceWith!;
        _flipped = false;
      });
      return;
    }

    if (outcome.advanceWithoutPersist) {
      _gotoNext();
      return;
    }
  }

  void _discardFunctionCard() {
    if (_processing) return;
    HapticFeedback.lightImpact();
    _gotoNext();
  }

  // ----------------------------- Build -----------------------------

  @override
  Widget build(BuildContext context) {
    final result = _current;
    final rarity = result.taskCard?.rarity ?? CardRarity.r;
    final accent = rarity.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            accent.withOpacity(0.35),
            AppColors.bg,
            AppColors.bg,
          ],
          stops: const [0, 0.55, 1],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // 爆发光效（盖在整个弹层上，但仅在卡片区附近"工作"）
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: RarityBurst(
                  // 每翻一张换一次 key，让特效重新爆一次
                  key: ValueKey('burst-$_index-${rarity.code}'),
                  rarity: rarity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dragHandle(),
                  const SizedBox(height: 8),
                  _rarityHeader(rarity, result),
                  const SizedBox(height: 12),
                  _flipArea(result, accent),
                  const SizedBox(height: 14),
                  if (_results.length > 1)
                    Text(
                      '${_index + 1} / ${_results.length}',
                      style: AppTextStyles.caption,
                    ),
                  const SizedBox(height: 12),
                  _footer(result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 48,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.primaryDim,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _rarityHeader(CardRarity rarity, DrawResult result) {
    final label = result.isFunction ? '功能卡' : rarity.code;
    final color = result.isFunction ? AppColors.primary : rarity.color;

    final base = Text(
      '✦  $label  ✦',
      style: AppTextStyles.displayLarge.copyWith(
        color: color,
        shadows: [
          Shadow(color: color.withOpacity(0.8), blurRadius: 24),
        ],
      ),
    );

    // SSR / UR 给标题加 shimmer 横扫，强化"哇"感
    if (rarity == CardRarity.ssr || rarity == CardRarity.ur) {
      return base
          .animate(key: ValueKey('hdr-$_index-${rarity.code}'))
          .fadeIn(duration: 360.ms)
          .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1))
          .shimmer(
            duration: 1200.ms,
            color: Colors.white.withOpacity(0.85),
            delay: 200.ms,
          );
    }
    return base
        .animate(key: ValueKey('hdr-$_index-${rarity.code}'))
        .fadeIn(duration: 360.ms)
        .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1));
  }

  Widget _flipArea(DrawResult result, Color accent) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: CardFlip2D(
          // 用 key 让每张卡都能从背面重新翻
          key: ValueKey('flip-$_index-${result.taskCard?.id ?? result.functionCard?.id}'),
          back: _cardBack(accent),
          front: _cardFront(result, accent),
          onFlipped: () {
            if (!mounted) return;
            setState(() => _flipped = true);
          },
        ),
      ),
    );
  }

  Widget _cardBack(Color accent) {
    return Container(
      width: 280,
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1429), Color(0xFF0F0816)],
        ),
        border: Border.all(color: accent.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.55), blurRadius: 28),
        ],
      ),
      child: Center(
        child: Icon(Icons.local_florist,
            color: accent.withOpacity(0.7), size: 56),
      ),
    );
  }

  Widget _cardFront(DrawResult result, Color accent) {
    final card = result.taskCard;
    final fn = result.functionCard;
    final isFunction = result.isFunction;
    final title = card?.title ?? fn?.title ?? '';
    final desc = result.customWishText ?? card?.description ?? fn?.description ?? '';

    String? executorLabel;
    if (card != null) {
      executorLabel = _executorLabelFor(result);
    }

    final body = Container(
      width: 280,
      constraints: const BoxConstraints(minHeight: 360),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.75), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.45), blurRadius: 30),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFunction)
            _chip('功能卡', accent)
          else if (result.grantedBy != null)
            _chip('来自 · ${result.grantedBy!.title}', accent),
          if (isFunction || result.grantedBy != null) const SizedBox(height: 10),
          if (result.customWishText != null) _chip('心愿', accent),
          if (result.customWishText != null) const SizedBox(height: 10),
          if (result.rewardMultiplier > 1) _chip('奖励 ×${result.rewardMultiplier}', accent),
          if (result.rewardMultiplier > 1) const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(color: accent),
          ),
          if (executorLabel != null) ...[
            const SizedBox(height: 8),
            Text('— $executorLabel —', style: AppTextStyles.caption),
          ],
          const SizedBox(height: 18),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
          ),
        ],
      ),
    );

    // 翻面完成后再叠一层 shimmer 流光描边
    if (!_flipped) return body;
    return body
        .animate(
            key: ValueKey('front-$_index-${card?.id ?? fn?.id}'),
            onPlay: (c) => c.repeat())
        .shimmer(
          duration: 2600.ms,
          color: accent.withOpacity(0.55),
        );
  }

  Widget _chip(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: accent, letterSpacing: 2)),
    );
  }

  Widget _footer(DrawResult result) {
    if (result.isFunction) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: _processing ? null : _discardFunctionCard,
            child: Text('丢弃',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          GoldButton(
            label: '使用',
            icon: Icons.auto_awesome,
            onPressed: _processing ? null : _useFunctionCard,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: _processing ? null : _skip,
          child: Text('跳过',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        GoldButton(
          label: '接受 ❤',
          icon: Icons.favorite,
          onPressed: _processing ? null : _accept,
        ),
      ],
    );
  }
}
