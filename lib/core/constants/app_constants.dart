/// PRD 中提到的固定常量
class AppConstants {
  AppConstants._();

  // 抽卡概率（PRD §6.2）
  static const Map<int, Map<String, double>> rarityWeights = {
    1: {'R': 0.70, 'SR': 0.25, 'SSR': 0.05},
    2: {'R': 0.60, 'SR': 0.30, 'SSR': 0.10},
    3: {'R': 0.50, 'SR': 0.35, 'SSR': 0.15},
    4: {'R': 0.50, 'SR': 0.35, 'SSR': 0.15},
  };

  static const int pityThreshold = 10;
  static const double functionCardDrawChance = 0.10;

  // 完成积分（PRD §8.1）
  static const Map<String, int> rarityScore = {'R': 10, 'SR': 30, 'SSR': 80};

  // 跳过限制（PRD §9.2）
  static const Map<int, int> dailySkipLimit = {1: 3, 2: 3, 3: 3, 4: 6};

  // 等级元数据
  static const List<LevelInfo> levels = [
    LevelInfo(level: 1, name: '甜蜜日常', tagline: '拥抱·夸赞·牵手', symbol: '✿'),
    LevelInfo(level: 2, name: '心动暧昧', tagline: '亲吻·耳语·撒娇', symbol: '♡'),
    LevelInfo(level: 3, name: '亲密互动', tagline: '按摩·蒙眼·游戏', symbol: '❦'),
    LevelInfo(level: 4, name: '私密大胆', tagline: '✦  仅限 18+  ✦', symbol: '🔒'),
  ];
}

class LevelInfo {
  final int level;
  final String name;
  final String tagline;
  final String symbol;
  const LevelInfo({
    required this.level,
    required this.name,
    required this.tagline,
    required this.symbol,
  });
}
