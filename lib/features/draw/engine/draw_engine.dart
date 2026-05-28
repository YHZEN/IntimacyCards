import 'dart:math';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/intimacy_card.dart';
import '../../../data/models/card_rarity.dart';
import '../../../data/repositories/settings_repository.dart';

/// 抽卡引擎 · PRD §7
///
/// - 维护 pity 计数（跨会话持久化到 settings 表）
/// - 维护最近 10 抽内存缓存，避免短时间内重复
/// - 单抽 / 十连，十连内保底 1 张 SSR
class DrawEngine {
  static const _pityKey = 'pity_counter';
  static const int _recentMemory = 10;

  final Random _random;
  final SettingsRepository? _settings;

  int _pityCounter = 0;
  final List<String> _recentDraws = [];
  Future<void>? _loadFuture;

  DrawEngine({Random? random, SettingsRepository? settings})
      : _random = random ?? Random(),
        _settings = settings;

  /// 启动时调用一次：从 settings 表恢复 pity。
  ///
  /// 也可以不主动调用，第一次 `draw()` / `tenPull()` 会内部 lazy 加载。
  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final repo = _settings;
    if (repo == null) return;
    final v = await repo.getInt(_pityKey);
    if (v != null) _pityCounter = v.clamp(0, AppConstants.pityThreshold);
  }

  void _persistPity() {
    // 故意 fire-and-forget：抽卡 UI 链路不该被一次 SQLite 写阻塞
    _settings?.setInt(_pityKey, _pityCounter);
  }

  /// 单抽
  Future<DrawResult> draw({
    required int level,
    required List<IntimacyCard> levelPool,
    required List<FunctionCard> functionPool,
    required List<String> excludedComfortTags,
  }) async {
    await ensureLoaded();
    return _drawSync(
      level: level,
      levelPool: levelPool,
      functionPool: functionPool,
      excludedComfortTags: excludedComfortTags,
    );
  }

  /// 功能卡用：保证抽到任务卡（不会再触发功能卡，避免套娃）。
  ///
  /// 仍然消耗 / 重置 pity，确保保底逻辑一致。
  Future<DrawResult> drawTaskOnly({
    required int level,
    required List<IntimacyCard> levelPool,
    required List<String> excludedComfortTags,
  }) async {
    await ensureLoaded();
    return _drawSync(
      level: level,
      levelPool: levelPool,
      functionPool: const [], // 空池 → 永远不会进入功能卡分支
      excludedComfortTags: excludedComfortTags,
    );
  }

  /// 十连抽：保底十连内必出 1 张 SSR
  Future<List<DrawResult>> tenPull({
    required int level,
    required List<IntimacyCard> levelPool,
    required List<FunctionCard> functionPool,
    required List<String> excludedComfortTags,
  }) async {
    await ensureLoaded();

    final results = <DrawResult>[];
    var hasSSR = false;

    for (int i = 0; i < 10; i++) {
      // 最后一抽如果还没出 SSR，强制保底触发
      if (i == 9 && !hasSSR) {
        _pityCounter = AppConstants.pityThreshold;
      }
      final r = _drawSync(
        level: level,
        levelPool: levelPool,
        functionPool: functionPool,
        excludedComfortTags: excludedComfortTags,
      );
      if (r.taskCard?.rarity == CardRarity.ssr) hasSSR = true;
      results.add(r);
    }
    return results;
  }

  DrawResult _drawSync({
    required int level,
    required List<IntimacyCard> levelPool,
    required List<FunctionCard> functionPool,
    required List<String> excludedComfortTags,
  }) {
    // 1. 10% 概率抽功能卡（功能卡不消耗 pity，不计入 recent）
    if (_random.nextDouble() < AppConstants.functionCardDrawChance &&
        functionPool.isNotEmpty) {
      final fn = functionPool[_random.nextInt(functionPool.length)];
      return DrawResult.function(fn);
    }

    // 2. 决定稀有度
    CardRarity rarity;
    if (_pityCounter >= AppConstants.pityThreshold) {
      rarity = CardRarity.ssr;
      _pityCounter = 0;
    } else {
      rarity = _pickRarityByLevel(level);
      if (rarity == CardRarity.ssr) {
        _pityCounter = 0;
      } else {
        _pityCounter++;
      }
    }
    _persistPity();

    // 3. 筛选候选池：等级 + 稀有度 + 舒适度排除 + 最近未抽
    var pool = levelPool
        .where((c) => c.rarity == rarity)
        .where((c) => !c.comfortTags.any(excludedComfortTags.contains))
        .toList();

    // 排除最近 10 抽，但池子太小时放宽
    final filteredByRecent =
        pool.where((c) => !_recentDraws.contains(c.id)).toList();
    if (filteredByRecent.isNotEmpty) pool = filteredByRecent;

    // 候选为空（稀有度池被全部排除），降级到 R 重试一次
    if (pool.isEmpty && rarity != CardRarity.r) {
      pool = levelPool
          .where((c) => c.rarity == CardRarity.r)
          .where((c) => !c.comfortTags.any(excludedComfortTags.contains))
          .toList();
    }

    if (pool.isEmpty) {
      throw StateError(
          'No drawable cards: level=$level, excluded=$excludedComfortTags');
    }

    final card = pool[_random.nextInt(pool.length)];
    _recordRecent(card.id);
    return DrawResult.task(card);
  }

  int get pityCounter => _pityCounter;
  int get pityRemaining => AppConstants.pityThreshold - _pityCounter;

  CardRarity _pickRarityByLevel(int level) {
    final weights =
        AppConstants.rarityWeights[level] ?? AppConstants.rarityWeights[1]!;
    final r = _random.nextDouble();
    double acc = 0;
    for (final entry in weights.entries) {
      acc += entry.value;
      if (r < acc) return CardRarity.parse(entry.key);
    }
    return CardRarity.r;
  }

  void _recordRecent(String id) {
    _recentDraws.add(id);
    if (_recentDraws.length > _recentMemory) {
      _recentDraws.removeAt(0);
    }
  }
}

/// 抽卡结果——可能是任务卡，也可能是功能卡。
///
/// 功能卡使用后会"临场"再抽一张任务卡作为它的作用对象，
/// 用 [grantedBy] / [executorOverride] / [rewardMultiplier] / [customWishText]
/// 等字段把功能卡施加的修饰一并带在这张新任务卡上。
class DrawResult {
  final IntimacyCard? taskCard;
  final FunctionCard? functionCard;

  /// 这张任务卡是被哪张功能卡修饰过来的；功能卡本身翻面时该字段为 null。
  final FunctionCard? grantedBy;

  /// 覆盖任务卡上预设的 executor（反转 / 镜像 / 协助 用）
  final CardExecutor? executorOverride;

  /// 完成时亲密度奖励倍率（加注卡用）
  final int rewardMultiplier;

  /// 心愿卡：用户自填心愿内容，非空时翻面将展示这段文字而不是原描述
  final String? customWishText;

  bool get isFunction => functionCard != null && taskCard == null;
  bool get isTask => taskCard != null;

  CardExecutor get effectiveExecutor =>
      executorOverride ?? taskCard?.executor ?? CardExecutor.loser;

  const DrawResult.task(
    IntimacyCard this.taskCard, {
    this.grantedBy,
    this.executorOverride,
    this.rewardMultiplier = 1,
    this.customWishText,
  }) : functionCard = null;

  const DrawResult.function(FunctionCard this.functionCard)
      : taskCard = null,
        grantedBy = null,
        executorOverride = null,
        rewardMultiplier = 1,
        customWishText = null;

  DrawResult copyWith({
    CardExecutor? executorOverride,
    int? rewardMultiplier,
    FunctionCard? grantedBy,
    String? customWishText,
  }) {
    assert(taskCard != null, 'copyWith only meaningful for task results');
    return DrawResult.task(
      taskCard!,
      grantedBy: grantedBy ?? this.grantedBy,
      executorOverride: executorOverride ?? this.executorOverride,
      rewardMultiplier: rewardMultiplier ?? this.rewardMultiplier,
      customWishText: customWishText ?? this.customWishText,
    );
  }
}
