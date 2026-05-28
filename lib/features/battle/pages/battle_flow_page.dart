import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/couple_profile.dart';
import '../../../providers.dart';
import '../../../router.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/midnight_scaffold.dart';
import '../../draw/widgets/card_reveal_sheet.dart';
import '../minigames/battle_minigames.dart';
import '../models/battle_models.dart';
import '../widgets/battle_player_strip.dart';

/// 对战主流程 · PRD §8.1
class BattleFlowPage extends ConsumerStatefulWidget {
  final int level;
  final int rounds;

  const BattleFlowPage({
    super.key,
    required this.level,
    this.rounds = 5,
  });

  @override
  ConsumerState<BattleFlowPage> createState() => _BattleFlowPageState();
}

class _BattleFlowPageState extends ConsumerState<BattleFlowPage> {
  late BattleSession _session;
  BattlePhase _phase = BattlePhase.firstTurnCoin;
  int _lastRoundScore = 0;
  BattleSide? _minigameActiveSide;

  LevelInfo get _levelInfo =>
      AppConstants.levels.firstWhere((l) => l.level == widget.level);

  @override
  void initState() {
    super.initState();
    _session = BattleSession(
      level: widget.level,
      totalRounds: widget.rounds,
    );
  }

  void _setPhase(BattlePhase phase) => setState(() => _phase = phase);

  void _onFirstTurnDecided(BattleSide first) {
    setState(() {
      _session = _session.copyWith(firstPlayer: first);
      _phase = BattlePhase.minigamePick;
    });
  }

  void _pickMinigame(BattleMinigame game) {
    setState(() {
      _session = _session.copyWith(selectedMinigame: game);
      _phase = BattlePhase.minigamePlay;
      _minigameActiveSide = _session.firstPlayer;
    });
  }

  void _pickRandomMinigame() {
    final games = BattleMinigame.values;
    _pickMinigame(games[Random().nextInt(games.length)]);
  }

  void _onMinigameWon(BattleSide winner) {
    setState(() {
      _session = _session.copyWith(
        roundWinner: winner,
        lastRoundLoser: winner.opponent,
      );
      _phase = BattlePhase.minigameResult;
    });
  }

  Future<void> _winnerDraw() async {
    _setPhase(BattlePhase.winnerDraw);
    HapticFeedback.heavyImpact();

    final cards = await ref.read(cardRepoProvider).byLevel(widget.level);
    final fns = await ref.read(cardRepoProvider).functionCards();
    final profile = ref.read(coupleProfileProvider).valueOrNull;
    final excluded = profile?.excludedComfortTags ?? const <String>[];

    final engine = ref.read(drawEngineProvider);
    final result = await engine.draw(
      level: widget.level,
      levelPool: cards,
      functionPool: fns,
      excludedComfortTags: excluded,
    );

    if (!mounted) return;

    final winner = _session.roundWinner!;
    final loser = winner.opponent;
    final profileData = profile!;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardRevealSheet(
        results: [result],
        drawLevel: widget.level,
        battleContext: BattleRevealContext(
          winnerName: winner.name(profileData),
          loserName: loser.name(profileData),
          onFinished: ({required completed, required roundScore}) {
            _lastRoundScore = roundScore;
            if (completed) {
              _session.addScore(winner, roundScore);
            }
          },
        ),
      ),
    );

    if (!mounted) return;
    _setPhase(BattlePhase.roundSummary);
  }

  void _nextRound() {
    if (_session.currentRound >= _session.totalRounds) {
      _setPhase(BattlePhase.finalResult);
      return;
    }

    setState(() {
      _session = _session.copyWith(
        currentRound: _session.currentRound + 1,
        firstPlayer: _session.lastRoundLoser ?? _session.firstPlayer,
        selectedMinigame: null,
        roundWinner: null,
      );
      _phase = BattlePhase.minigamePick;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(coupleProfileProvider).valueOrNull;
    if (profile == null) {
      return const MidnightScaffold(
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => _confirmExit(context),
        ),
        title: Text(
          '对战 · Lv.${widget.level} ${_levelInfo.name}',
          style: AppTextStyles.titleMedium,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${_session.currentRound}/${_session.totalRounds}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: BattlePlayerStrip(
                profile: profile,
                activeSide: _activeSide(),
                winnerSide: _phase == BattlePhase.minigameResult ||
                        _phase == BattlePhase.roundSummary
                    ? _session.roundWinner
                    : null,
                scores: _session.scores,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _phaseBody(profile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BattleSide? _activeSide() {
    if (_phase == BattlePhase.minigamePlay) {
      return _minigameActiveSide ?? _session.firstPlayer;
    }
    return null;
  }

  Widget _minigamePanel(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryDim),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _phaseBody(CoupleProfile profile) {
    return switch (_phase) {
      BattlePhase.firstTurnCoin => _minigamePanel(
          FirstTurnCoinFlip(
            profile: profile,
            onComplete: _onFirstTurnDecided,
          ),
        ),
      BattlePhase.minigamePick => _minigamePicker(profile),
      BattlePhase.minigamePlay => _minigamePlay(profile),
      BattlePhase.minigameResult => _minigamePanel(_minigameResult(profile)),
      BattlePhase.winnerDraw => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      BattlePhase.roundSummary => _minigamePanel(_roundSummary(profile)),
      BattlePhase.finalResult => _minigamePanel(_finalResult(profile)),
    };
  }

  Widget _minigamePicker(CoupleProfile profile) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Text(
          '选择小游戏',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '第 ${_session.currentRound} 回合 · ${_session.firstPlayer?.name(profile) ?? ''} 先出',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 24),
        for (final game in BattleMinigame.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _minigameTile(game),
          ),
        _randomTile(),
      ],
    );
  }

  Widget _minigameTile(BattleMinigame game) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _pickMinigame(game);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryDim),
        ),
        child: Row(
          children: [
            Text(game.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(game.label, style: AppTextStyles.bodyLarge),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primaryDim),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _randomTile() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _pickRandomMinigame();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            const Text('🎲', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Text('随机 · 惊喜一把', style: AppTextStyles.bodyLarge),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primaryDim),
          ],
        ),
      ),
    );
  }

  Widget _minigamePlay(CoupleProfile profile) {
    final first = _session.firstPlayer!;
    final game = _session.selectedMinigame!;
    final onActive = (BattleSide? side) {
      if (mounted) setState(() => _minigameActiveSide = side);
    };

    return _minigamePanel(
      switch (game) {
        BattleMinigame.rps => RpsMinigame(
            profile: profile,
            firstPlayer: first,
            onComplete: _onMinigameWon,
            onActiveSideChanged: onActive,
          ),
        BattleMinigame.dice => DiceMinigame(
            profile: profile,
            firstPlayer: first,
            onComplete: _onMinigameWon,
            onActiveSideChanged: onActive,
          ),
        BattleMinigame.coin => CoinDuelMinigame(
            profile: profile,
            firstPlayer: first,
            onComplete: _onMinigameWon,
            onActiveSideChanged: onActive,
          ),
      },
    );
  }

  Widget _minigameResult(CoupleProfile profile) {
    final winner = _session.roundWinner!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          Text('✦',
              style:
                  AppTextStyles.displayLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(
            '${winner.name(profile)} 胜利',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.primary,
              shadows: [
                Shadow(color: AppColors.primary.withOpacity(0.7), blurRadius: 20),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),
          const SizedBox(height: 12),
          Text(
            '赢家抽卡 · 输家执行',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          GoldButton(
            label: '赢家抽卡',
            icon: Icons.auto_awesome,
            onPressed: _winnerDraw,
          ),
        ],
    );
  }

  Widget _roundSummary(CoupleProfile profile) {
    final winner = _session.roundWinner!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          Text('回合 ${_session.currentRound} 结束',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          if (_lastRoundScore > 0)
            Text(
              '${winner.name(profile)} +$_lastRoundScore 分',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
            ),
          const SizedBox(height: 24),
          _scoreBoard(profile),
          const SizedBox(height: 32),
          GoldButton(
            label: _session.currentRound >= _session.totalRounds
                ? '查看终局'
                : '下一回合',
            icon: Icons.arrow_forward,
            onPressed: _nextRound,
          ),
        ],
    );
  }

  Widget _finalResult(CoupleProfile profile) {
    final overall = _session.overallWinner;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          Text('终局结算', style: AppTextStyles.titleMedium),
          const SizedBox(height: 24),
          _scoreBoard(profile),
          const SizedBox(height: 24),
          if (overall != null) ...[
            Text(
              '${overall.name(profile)} 总分领先 ✦',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.primary,
                fontSize: 28,
              ),
            ).animate().fadeIn().shimmer(duration: 1200.ms),
            const SizedBox(height: 12),
            Text(
              '获得一次心愿卡奖励',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent),
            ),
          ] else
            Text(
              '势均力敌 · 平局',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 32),
          GoldButton(
            label: '返回主页',
            icon: Icons.home_outlined,
            width: double.infinity,
            onPressed: () => context.go(Routes.home),
          ),
        ],
    );
  }

  Widget _scoreBoard(CoupleProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDim),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scoreColumn(profile.myName, _session.scores[BattleSide.self] ?? 0),
          Text(':', style: AppTextStyles.titleLarge),
          _scoreColumn(
              profile.partnerName, _session.scores[BattleSide.partner] ?? 0),
        ],
      ),
    );
  }

  Widget _scoreColumn(String name, int score) {
    return Column(
      children: [
        Text(name, style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Text('$score', style: AppTextStyles.displayLarge.copyWith(fontSize: 36)),
      ],
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('退出对战？', style: AppTextStyles.titleMedium),
        content: Text('当前进度不会保存', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('继续',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('退出',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) context.pop();
  }
}
