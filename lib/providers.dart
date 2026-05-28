import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database/app_database.dart';
import 'data/models/couple_profile.dart';
import 'data/models/diary_entry.dart';
import 'data/models/intimacy_card.dart';
import 'data/repositories/card_repository.dart';
import 'data/repositories/couple_repository.dart';
import 'data/repositories/diary_repository.dart';
import 'data/repositories/draw_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'features/draw/engine/draw_engine.dart';

/// 全局 Provider 注册中心
///
/// 简单粗暴用 `Provider` 而不是 `riverpod_generator`，
/// 避免 build_runner 依赖，让骨架开箱可跑。

// ---- 仓储 ----
final cardRepoProvider = Provider<CardRepository>((_) => CardRepository());
final coupleRepoProvider = Provider<CoupleRepository>((_) => CoupleRepository());
final diaryRepoProvider = Provider<DiaryRepository>((_) => DiaryRepository());
final drawRepoProvider = Provider<DrawRepository>((_) => DrawRepository());
final settingsRepoProvider =
    Provider<SettingsRepository>((_) => SettingsRepository());

// ---- 抽卡引擎（全局单例）----
final drawEngineProvider = Provider<DrawEngine>(
  (ref) => DrawEngine(settings: ref.read(settingsRepoProvider)),
);

// ---- 情侣资料（用 AsyncNotifier 处理异步加载与变更）----
class CoupleProfileNotifier extends AsyncNotifier<CoupleProfile?> {
  @override
  Future<CoupleProfile?> build() async {
    return ref.read(coupleRepoProvider).load();
  }

  Future<void> save(CoupleProfile profile) async {
    state = const AsyncValue.loading();
    await ref.read(coupleRepoProvider).save(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> switchUser() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = current.currentUser == CurrentUser.self
        ? CurrentUser.partner
        : CurrentUser.self;
    final updated = current.copyWith(currentUser: next);
    await ref.read(coupleRepoProvider).save(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> addIntimacyExp(int exp) async {
    await ref.read(coupleRepoProvider).addIntimacyExp(exp);
    state = AsyncValue.data(await ref.read(coupleRepoProvider).load());
  }
}

final coupleProfileProvider =
    AsyncNotifierProvider<CoupleProfileNotifier, CoupleProfile?>(
  CoupleProfileNotifier.new,
);

// ---- 卡片计数（图鉴用）----
final cardCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  return ref.read(cardRepoProvider).countsByLevel();
});

final customCardsProvider = FutureProvider<List<IntimacyCard>>((ref) async {
  return ref.read(cardRepoProvider).customCards();
});

final collectedCardIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.read(drawRepoProvider).collectedCardIds();
});

/// 已收集卡片按等级分组计数：{level: collectedCount}
final collectedCountsByLevelProvider =
    FutureProvider<Map<int, int>>((ref) async {
  final db = await AppDatabase.instance();
  final rows = await db.rawQuery('''
    SELECT c.level AS level, COUNT(DISTINCT d.card_id) AS c
    FROM draws d
    JOIN cards c ON c.id = d.card_id
    WHERE d.is_completed = 1
    GROUP BY c.level
  ''');
  return {for (final r in rows) r['level'] as int: r['c'] as int};
});

/// 累计抽卡次数（包括跳过的）
final totalDrawsProvider = FutureProvider<int>((ref) async {
  final db = await AppDatabase.instance();
  final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM draws');
  return (rows.first['c'] as int?) ?? 0;
});

final diaryCountProvider = FutureProvider<int>((ref) async {
  return ref.read(diaryRepoProvider).count();
});

final diaryEntriesProvider = FutureProvider<List<DiaryEntryView>>((ref) async {
  return ref.read(diaryRepoProvider).richEntries();
});
