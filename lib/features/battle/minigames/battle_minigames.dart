import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/couple_profile.dart';
import '../../../shared/widgets/gold_button.dart';
import '../models/battle_models.dart';
import '../widgets/pass_phone_gate.dart';

enum RpsChoice { rock, scissors, paper }

/// 石头剪刀布 · 三局两胜 · PRD §8.2.1
class RpsMinigame extends StatefulWidget {
  final CoupleProfile profile;
  final BattleSide firstPlayer;
  final void Function(BattleSide winner) onComplete;
  final ValueChanged<BattleSide?>? onActiveSideChanged;

  const RpsMinigame({
    super.key,
    required this.profile,
    required this.firstPlayer,
    required this.onComplete,
    this.onActiveSideChanged,
  });

  @override
  State<RpsMinigame> createState() => _RpsMinigameState();
}

class _RpsMinigameState extends State<RpsMinigame> {
  int _round = 1;
  int _selfWins = 0;
  int _partnerWins = 0;
  RpsChoice? _firstChoice;
  RpsChoice? _secondChoice;
  bool _showingResult = false;
  String? _resultText;

  BattleSide get _secondPlayer => widget.firstPlayer.opponent;

  static const _choices = [
    (RpsChoice.rock, '🌹', '石'),
    (RpsChoice.scissors, '✂️', '剪'),
    (RpsChoice.paper, '✋', '布'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onActiveSideChanged?.call(widget.firstPlayer);
    });
  }

  void _notifyActive(BattleSide? side) {
    widget.onActiveSideChanged?.call(side);
  }

  Future<void> _pick(RpsChoice choice, BattleSide picker) async {
    if (_showingResult) return;

    if (picker == widget.firstPlayer && _firstChoice == null) {
      setState(() => _firstChoice = choice);
      HapticFeedback.selectionClick();
      if (!mounted) return;
      // 仅石头剪刀布：递手机蒙版，防止对方看到选择
      await PassPhoneGate.show(
        context,
        profile: widget.profile,
        expectedSide: _secondPlayer,
      );
      if (!mounted) return;
      _notifyActive(_secondPlayer);
      return;
    }

    if (picker == _secondPlayer && _firstChoice != null && _secondChoice == null) {
      setState(() => _secondChoice = choice);
      HapticFeedback.mediumImpact();
      _resolveRound();
    }
  }

  void _resolveRound() {
    final winner = _judge(_firstChoice!, _secondChoice!);
    setState(() {
      _showingResult = true;
      if (winner == widget.firstPlayer) {
        if (widget.firstPlayer == BattleSide.self) {
          _selfWins++;
        } else {
          _partnerWins++;
        }
      } else if (winner == _secondPlayer) {
        if (_secondPlayer == BattleSide.self) {
          _selfWins++;
        } else {
          _partnerWins++;
        }
      }

      if (winner == null) {
        _resultText = '平局 · 再来一局';
      } else {
        _resultText = '${winner.name(widget.profile)} 本局胜';
      }
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_selfWins >= 2) {
        widget.onComplete(BattleSide.self);
        return;
      }
      if (_partnerWins >= 2) {
        widget.onComplete(BattleSide.partner);
        return;
      }
      setState(() {
        _round++;
        _firstChoice = null;
        _secondChoice = null;
        _showingResult = false;
        _resultText = null;
      });
      _notifyActive(widget.firstPlayer);
    });
  }

  BattleSide? _judge(RpsChoice a, RpsChoice b) {
    if (a == b) return null;
    final wins = {
      RpsChoice.rock: RpsChoice.scissors,
      RpsChoice.scissors: RpsChoice.paper,
      RpsChoice.paper: RpsChoice.rock,
    };
    return wins[a] == b ? widget.firstPlayer : _secondPlayer;
  }

  String _choiceLabel(RpsChoice? c, {required bool hidden}) {
    if (c == null || hidden) return '?';
    return _choices.firstWhere((e) => e.$1 == c).$2;
  }

  /// 先手已选、后手未选时，隐藏先手出牌
  bool get _hideFirstChoice =>
      _firstChoice != null && _secondChoice == null && !_showingResult;

  @override
  Widget build(BuildContext context) {
    final waitingSecond = _firstChoice != null && _secondChoice == null;
    final activeSide = waitingSecond
        ? _secondPlayer
        : (_firstChoice == null ? widget.firstPlayer : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '石头剪刀布 · 三局两胜',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '第 $_round 局 · $_selfWins : $_partnerWins',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        if (_resultText != null)
          Text(_resultText!,
                  style:
                      AppTextStyles.titleMedium.copyWith(color: AppColors.accent))
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        if (_resultText != null) const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _choiceDisplay(
              widget.firstPlayer.name(widget.profile),
              _choiceLabel(_firstChoice, hidden: _hideFirstChoice),
              masked: _hideFirstChoice,
            ),
            Text('VS', style: AppTextStyles.caption),
            _choiceDisplay(
              _secondPlayer.name(widget.profile),
              _choiceLabel(_secondChoice, hidden: false),
            ),
          ],
        ),
        if (_hideFirstChoice) ...[
          const SizedBox(height: 8),
          Text(
            '对方已出招 · 请保密',
            style: AppTextStyles.caption.copyWith(color: AppColors.textDim),
          ),
        ],
        const SizedBox(height: 20),
        if (!_showingResult && activeSide != null) ...[
          Text(
            '${activeSide.name(widget.profile)} 请选择',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final c in _choices)
                _choiceButton(c.$1, c.$2, c.$3, activeSide),
            ],
          ),
        ],
      ],
    );
  }

  Widget _choiceDisplay(String name, String emoji, {bool masked = false}) {
    return Column(
      children: [
        Text(name, style: AppTextStyles.caption),
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: masked ? AppColors.bg : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: masked ? AppColors.primaryDim : AppColors.primaryDim,
            ),
          ),
          child: masked
              ? Icon(Icons.lock_outline,
                  color: AppColors.primary.withOpacity(0.6), size: 28)
              : Text(emoji, style: const TextStyle(fontSize: 36)),
        ),
      ],
    );
  }

  Widget _choiceButton(
    RpsChoice choice,
    String emoji,
    String label,
    BattleSide picker,
  ) {
    return GestureDetector(
      onTap: () => _pick(choice, picker),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// 首发翻硬币 · 决定谁先出招
class FirstTurnCoinFlip extends StatefulWidget {
  final CoupleProfile profile;
  final void Function(BattleSide firstPlayer) onComplete;

  const FirstTurnCoinFlip({
    super.key,
    required this.profile,
    required this.onComplete,
  });

  @override
  State<FirstTurnCoinFlip> createState() => _FirstTurnCoinFlipState();
}

class _FirstTurnCoinFlipState extends State<FirstTurnCoinFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  bool _flipping = false;
  bool? _isHeads;
  BattleSide? _firstPlayer;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _flip() async {
    if (_flipping) return;
    setState(() {
      _flipping = true;
      _firstPlayer = null;
    });
    HapticFeedback.heavyImpact();

    final heads = Random().nextBool();
    await _spin.forward(from: 0);

    final first = heads ? BattleSide.self : BattleSide.partner;
    setState(() {
      _isHeads = heads;
      _firstPlayer = first;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) widget.onComplete(first);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('首发决定', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        Text(
          '翻硬币决定谁先出招',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        RotationTransition(
          turns: Tween(begin: 0.0, end: 6.0).animate(
            CurvedAnimation(parent: _spin, curve: Curves.easeOutCubic),
          ),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [AppColors.primary, AppColors.primaryDim],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 24,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _isHeads == null ? '🪙' : (_isHeads! ? '正' : '反'),
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.bg),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_firstPlayer != null)
          Text(
            '${_firstPlayer!.name(widget.profile)} 先出招',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
          ).animate().fadeIn().scale(),
        const SizedBox(height: 24),
        GoldButton(
          label: _flipping ? '翻转中…' : '翻硬币',
          icon: Icons.casino_outlined,
          onPressed: _flipping ? null : _flip,
        ),
      ],
    );
  }
}

/// 色子比大小 · PRD §8.2.2
class DiceMinigame extends StatefulWidget {
  final CoupleProfile profile;
  final BattleSide firstPlayer;
  final void Function(BattleSide winner) onComplete;
  final ValueChanged<BattleSide?>? onActiveSideChanged;

  const DiceMinigame({
    super.key,
    required this.profile,
    required this.firstPlayer,
    required this.onComplete,
    this.onActiveSideChanged,
  });

  @override
  State<DiceMinigame> createState() => _DiceMinigameState();
}

class _DiceMinigameState extends State<DiceMinigame> {
  int? _firstRoll;
  int? _secondRoll;
  bool _rolling = false;
  final _rng = Random();

  BattleSide get _secondPlayer => widget.firstPlayer.opponent;

  static const _pip = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onActiveSideChanged?.call(widget.firstPlayer);
    });
  }

  void _notifyActive(BattleSide? side) {
    widget.onActiveSideChanged?.call(side);
  }

  Future<void> _roll(BattleSide roller) async {
    if (_rolling) return;

    if (roller == widget.firstPlayer && _firstRoll == null) {
      setState(() => _rolling = true);
      HapticFeedback.mediumImpact();
      await _animateRoll(isFirst: true);
      if (!mounted) return;
      _notifyActive(_secondPlayer);
      return;
    }

    if (roller == _secondPlayer && _firstRoll != null && _secondRoll == null) {
      setState(() => _rolling = true);
      HapticFeedback.mediumImpact();
      await _animateRoll(isFirst: false);
    }
  }

  Future<void> _animateRoll({required bool isFirst}) async {
    for (var i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        final v = _rng.nextInt(6) + 1;
        if (isFirst) {
          _firstRoll = v;
        } else {
          _secondRoll = v;
        }
      });
    }

    final finalRoll = _rng.nextInt(6) + 1;
    setState(() {
      if (isFirst) {
        _firstRoll = finalRoll;
      } else {
        _secondRoll = finalRoll;
      }
      _rolling = false;
    });

    if (!isFirst) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _resolve();
    }
  }

  void _resolve() {
    if (_firstRoll == _secondRoll) {
      setState(() {
        _firstRoll = null;
        _secondRoll = null;
      });
      _notifyActive(widget.firstPlayer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('平局 · 重掷', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.surfaceAlt,
        ),
      );
      return;
    }

    _notifyActive(null);
    final firstWins = _firstRoll! > _secondRoll!;
    final winner = firstWins ? widget.firstPlayer : _secondPlayer;
    widget.onComplete(winner);
  }

  @override
  Widget build(BuildContext context) {
    final waitingSecond = _firstRoll != null && _secondRoll == null;
    final activeSide = waitingSecond
        ? _secondPlayer
        : (_firstRoll == null ? widget.firstPlayer : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('色子比大小', style: AppTextStyles.titleMedium),
        const SizedBox(height: 6),
        Text(
          '点数大者胜 · 平局重掷',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _diceCell(
              widget.firstPlayer.name(widget.profile),
              _firstRoll,
            ),
            Text('VS', style: AppTextStyles.caption),
            _diceCell(
              _secondPlayer.name(widget.profile),
              _secondRoll,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (activeSide != null && !_rolling)
          GoldButton(
            label: '${activeSide.name(widget.profile)} 掷色子',
            icon: Icons.casino,
            onPressed: () => _roll(activeSide),
          ),
      ],
    );
  }

  Widget _diceCell(String name, int? value) {
    return Column(
      children: [
        Text(name, style: AppTextStyles.caption),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryDim),
          ),
          child: Text(
            value == null ? '🎲' : _pip[value - 1],
            style: TextStyle(fontSize: value == null ? 36 : 48),
          ),
        ),
        if (value != null) Text('$value 点', style: AppTextStyles.caption),
      ],
    );
  }
}

/// 翻硬币对决 · PRD §8.2.3
class CoinDuelMinigame extends StatefulWidget {
  final CoupleProfile profile;
  final BattleSide firstPlayer;
  final void Function(BattleSide winner) onComplete;
  final ValueChanged<BattleSide?>? onActiveSideChanged;

  const CoinDuelMinigame({
    super.key,
    required this.profile,
    required this.firstPlayer,
    required this.onComplete,
    this.onActiveSideChanged,
  });

  @override
  State<CoinDuelMinigame> createState() => _CoinDuelMinigameState();
}

class _CoinDuelMinigameState extends State<CoinDuelMinigame>
    with SingleTickerProviderStateMixin {
  bool? _firstPickHeads;
  bool? _resultHeads;
  bool _flipping = false;
  late final AnimationController _spin;

  BattleSide get _secondPlayer => widget.firstPlayer.opponent;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onActiveSideChanged?.call(widget.firstPlayer);
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _pick(bool heads) async {
    if (_firstPickHeads != null || _flipping) return;
    setState(() => _firstPickHeads = heads);
    HapticFeedback.selectionClick();
    widget.onActiveSideChanged?.call(null);
    await _flipCoin();
  }

  Future<void> _flipCoin() async {
    setState(() => _flipping = true);
    HapticFeedback.heavyImpact();
    final result = Random().nextBool();
    await _spin.forward(from: 0);
    setState(() => _resultHeads = result);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final firstWins = _firstPickHeads == result;
    widget.onComplete(firstWins ? widget.firstPlayer : _secondPlayer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('翻硬币', style: AppTextStyles.titleMedium),
        const SizedBox(height: 6),
        Text(
          '${widget.firstPlayer.name(widget.profile)} 猜正或反',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        if (_firstPickHeads == null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _sideButton('正面', true),
              _sideButton('反面', false),
            ],
          ),
        ] else if (_flipping || _resultHeads == null) ...[
          Text(
            '猜 ${_firstPickHeads! ? "正面" : "反面"} · 开 coin 中…',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
          ),
        ] else ...[
          Text(
            '结果 ${_resultHeads! ? "正面" : "反面"}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
          ),
        ],
        const SizedBox(height: 20),
        RotationTransition(
          turns: Tween(begin: 0.0, end: 5.0).animate(
            CurvedAnimation(parent: _spin, curve: Curves.easeOutCubic),
          ),
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.primary, AppColors.primaryDim],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _resultHeads == null ? '🪙' : (_resultHeads! ? '正' : '反'),
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.bg),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sideButton(String label, bool heads) {
    return GestureDetector(
      onTap: () => _pick(heads),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        ),
        child: Text(label,
            textAlign: TextAlign.center, style: AppTextStyles.titleSmall),
      ),
    );
  }
}
