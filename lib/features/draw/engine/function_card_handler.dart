import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/card_rarity.dart';
import '../../../data/models/intimacy_card.dart';
import '../../../providers.dart';
import '../widgets/replay_picker_sheet.dart';
import '../widgets/wish_input_sheet.dart';
import 'draw_engine.dart';

/// 功能卡的"使用"结果
///
/// 调用方 (CardRevealSheet) 据此决定如何更新 results / _index。
class FunctionCardOutcome {
  /// 用户取消了（关闭弹窗），保持当前位置不变（仍然显示这张功能卡）
  final bool cancelled;

  /// 当前这张已经处理完，前进到下一张（不再写 draws / diary）
  final bool advanceWithoutPersist;

  /// 用功能卡换出来的新任务卡，需要替换当前位置并展示
  final DrawResult? replaceWith;

  /// 提示文本（snackbar 用）
  final String? notice;

  const FunctionCardOutcome._({
    this.cancelled = false,
    this.advanceWithoutPersist = false,
    this.replaceWith,
    this.notice,
  });

  factory FunctionCardOutcome.cancelled() =>
      const FunctionCardOutcome._(cancelled: true);

  factory FunctionCardOutcome.skip({String? notice}) =>
      FunctionCardOutcome._(advanceWithoutPersist: true, notice: notice);

  factory FunctionCardOutcome.replace(DrawResult result, {String? notice}) =>
      FunctionCardOutcome._(replaceWith: result, notice: notice);
}

/// 功能卡效果分发器（参见 PRD §6.4 和 `data/cards.json` functionCards）。
class FunctionCardHandler {
  final WidgetRef ref;
  FunctionCardHandler(this.ref);

  /// 解析并应用功能卡。
  ///
  /// - [fn]            刚翻到的功能卡
  /// - [drawLevel]     当前等级选择页所选等级（重抽 / 升降级 的基线）
  /// - [context]       用于弹出输入框 / 选择器
  Future<FunctionCardOutcome> apply({
    required FunctionCard fn,
    required int drawLevel,
    required BuildContext context,
  }) async {
    switch (fn.effect) {
      case 'skip_free':
        return FunctionCardOutcome.skip(notice: '跳过 · 不计入跳过次数');

      case 'redraw':
        return _redraw(fn: fn, level: drawLevel);

      case 'downgrade_redraw':
        final next = math.max(1, drawLevel - 1);
        if (next == drawLevel) {
          return _redraw(fn: fn, level: drawLevel, notice: '已是最低等级，原级重抽');
        }
        return _redraw(fn: fn, level: next, notice: '降级到 Lv.$next');

      case 'upgrade_redraw':
        // Lv.4 是 18+ 区，不让功能卡静默把人推过去
        final next = math.min(3, drawLevel + 1);
        if (next == drawLevel) {
          return _redraw(fn: fn, level: drawLevel, notice: 'Lv.4 需独立解锁，原级重抽');
        }
        return _redraw(fn: fn, level: next, notice: '升级到 Lv.$next');

      case 'reverse_executor':
        return _modifiedDraw(
          fn: fn,
          level: drawLevel,
          transform: (c, base) => base.copyWith(
            executorOverride: _flip(c.executor),
          ),
          notice: '执行者反转',
        );

      case 'mirror_both':
      case 'set_both':
        return _modifiedDraw(
          fn: fn,
          level: drawLevel,
          transform: (_, base) => base.copyWith(
            executorOverride: CardExecutor.both,
          ),
          notice: '两人一起完成',
        );

      case 'double_reward':
        return _modifiedDraw(
          fn: fn,
          level: drawLevel,
          transform: (_, base) => base.copyWith(rewardMultiplier: 2),
          notice: '亲密度奖励 ×2',
        );

      case 'wish_replace':
        return _wishReplace(fn: fn, level: drawLevel, context: context);

      case 'replay_album':
        return _replayAlbum(fn: fn, context: context);

      default:
        return FunctionCardOutcome.skip(notice: '未知功能卡，已忽略');
    }
  }

  // ----------------------------- 私有实现 -----------------------------

  CardExecutor _flip(CardExecutor e) => switch (e) {
        CardExecutor.loser => CardExecutor.winner,
        CardExecutor.winner => CardExecutor.loser,
        CardExecutor.both => CardExecutor.both,
      };

  Future<FunctionCardOutcome> _redraw({
    required FunctionCard fn,
    required int level,
    String? notice,
  }) async {
    final pool = await ref.read(cardRepoProvider).byLevel(level);
    final excluded =
        ref.read(coupleProfileProvider).valueOrNull?.excludedComfortTags ??
            const <String>[];

    final engine = ref.read(drawEngineProvider);
    final r = await engine.drawTaskOnly(
      level: level,
      levelPool: pool,
      excludedComfortTags: excluded,
    );
    final task = r.taskCard;
    if (task == null) return FunctionCardOutcome.skip(notice: '没有可重抽的卡');

    return FunctionCardOutcome.replace(
      DrawResult.task(task, grantedBy: fn),
      notice: notice,
    );
  }

  Future<FunctionCardOutcome> _modifiedDraw({
    required FunctionCard fn,
    required int level,
    required DrawResult Function(IntimacyCard, DrawResult base) transform,
    String? notice,
  }) async {
    final base = await _redraw(fn: fn, level: level);
    final task = base.replaceWith?.taskCard;
    if (task == null) return base;
    final modified = transform(task, base.replaceWith!);
    return FunctionCardOutcome.replace(modified, notice: notice);
  }

  Future<FunctionCardOutcome> _wishReplace({
    required FunctionCard fn,
    required int level,
    required BuildContext context,
  }) async {
    final wish = await WishInputSheet.show(context);
    if (wish == null || wish.trim().isEmpty) {
      return FunctionCardOutcome.cancelled();
    }

    // 抽一张同等级的任务卡作为"载体"（保留稀有度、奖励等机制），
    // 但翻面时只展示用户的心愿文本而不展示卡的原描述。
    final pool = await ref.read(cardRepoProvider).byLevel(level);
    final excluded =
        ref.read(coupleProfileProvider).valueOrNull?.excludedComfortTags ??
            const <String>[];
    final engine = ref.read(drawEngineProvider);
    final r = await engine.drawTaskOnly(
      level: level,
      levelPool: pool,
      excludedComfortTags: excluded,
    );
    final task = r.taskCard;
    if (task == null) return FunctionCardOutcome.skip(notice: '没有可用的卡作为心愿载体');

    return FunctionCardOutcome.replace(
      DrawResult.task(
        task,
        grantedBy: fn,
        customWishText: wish.trim(),
        executorOverride: CardExecutor.loser, // 输家完成赢家的心愿
      ),
      notice: '心愿已记录',
    );
  }

  Future<FunctionCardOutcome> _replayAlbum({
    required FunctionCard fn,
    required BuildContext context,
  }) async {
    final collectedIds = ref.read(collectedCardIdsProvider).valueOrNull;
    if (collectedIds == null || collectedIds.isEmpty) {
      return FunctionCardOutcome.skip(notice: '图鉴还空着，无可重温');
    }

    final all = await ref.read(cardRepoProvider).all();
    final candidates =
        all.where((c) => collectedIds.contains(c.id)).toList(growable: false);
    if (candidates.isEmpty) {
      return FunctionCardOutcome.skip(notice: '图鉴还空着，无可重温');
    }

    final picked = await ReplayPickerSheet.show(context, candidates: candidates);
    if (picked == null) return FunctionCardOutcome.cancelled();

    return FunctionCardOutcome.replace(
      DrawResult.task(picked, grantedBy: fn),
      notice: '重温收藏',
    );
  }
}
