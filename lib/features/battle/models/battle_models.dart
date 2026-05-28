import '../../../data/models/couple_profile.dart';

/// 对战双方 · 映射 couple_profile 中的 self / partner
enum BattleSide {
  self,
  partner;

  BattleSide get opponent =>
      this == BattleSide.self ? BattleSide.partner : BattleSide.self;

  String name(CoupleProfile profile) =>
      this == BattleSide.self ? profile.myName : profile.partnerName;

  String avatarId(CoupleProfile profile) =>
      this == BattleSide.self ? profile.myAvatar : profile.partnerAvatar;
}

enum BattleMinigame {
  rps('石头剪刀布', '🌹✂️✋'),
  dice('色子比大小', '🎲'),
  coin('翻硬币', '🪙');

  final String label;
  final String emoji;
  const BattleMinigame(this.label, this.emoji);
}

enum BattlePhase {
  firstTurnCoin,
  minigamePick,
  minigamePlay,
  minigameResult,
  winnerDraw,
  roundSummary,
  finalResult,
}

/// 单局对战会话状态
class BattleSession {
  final int level;
  final int totalRounds;
  final Map<BattleSide, int> scores;

  int currentRound;
  BattleSide? firstPlayer;
  BattleMinigame? selectedMinigame;
  BattleSide? roundWinner;
  BattleSide? lastRoundLoser;

  BattleSession({
    required this.level,
    this.totalRounds = 5,
    Map<BattleSide, int>? scores,
    this.currentRound = 1,
    this.firstPlayer,
    this.selectedMinigame,
    this.roundWinner,
    this.lastRoundLoser,
  }) : scores = scores ?? {BattleSide.self: 0, BattleSide.partner: 0};

  bool get isFinished => currentRound > totalRounds;

  BattleSide? get overallWinner {
    final selfScore = scores[BattleSide.self] ?? 0;
    final partnerScore = scores[BattleSide.partner] ?? 0;
    if (selfScore == partnerScore) return null;
    return selfScore > partnerScore ? BattleSide.self : BattleSide.partner;
  }

  void addScore(BattleSide side, int points) {
    scores[side] = (scores[side] ?? 0) + points;
  }

  BattleSession copyWith({
    int? currentRound,
    BattleSide? firstPlayer,
    BattleMinigame? selectedMinigame,
    BattleSide? roundWinner,
    BattleSide? lastRoundLoser,
    Map<BattleSide, int>? scores,
  }) {
    return BattleSession(
      level: level,
      totalRounds: totalRounds,
      scores: scores ?? Map.of(this.scores),
      currentRound: currentRound ?? this.currentRound,
      firstPlayer: firstPlayer ?? this.firstPlayer,
      selectedMinigame: selectedMinigame ?? this.selectedMinigame,
      roundWinner: roundWinner ?? this.roundWinner,
      lastRoundLoser: lastRoundLoser ?? this.lastRoundLoser,
    );
  }
}
