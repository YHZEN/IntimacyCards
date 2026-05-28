import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/intimacy_card.dart';
import '../../core/constants/app_constants.dart';

class CardRepository {
  Future<Database> get _db => AppDatabase.instance();

  /// 按等级查询可抽取卡池
  ///
  /// - Lv.1–4：官方该级卡 + 混入该级的自制卡
  /// - Lv.5「定制的爱」：全部已启用的自制卡
  Future<List<IntimacyCard>> byLevel(int level) async {
    final db = await _db;
    if (level == AppConstants.customOnlyLevel) {
      final rows = await _queryCustomOnly(db);
      return _attachPoolLevels(
        db,
        rows.map(IntimacyCard.fromDbRow).toList(),
      );
    }

    final rows = await db.rawQuery('''
      SELECT DISTINCT c.*
      FROM cards c
      LEFT JOIN card_pool_levels p ON c.id = p.card_id
      WHERE c.enabled = 1 AND (
        (c.is_custom = 0 AND c.level = ?)
        OR (c.is_custom = 1 AND p.level = ?)
      )
    ''', [level, level]);
    return _attachPoolLevels(db, rows.map(IntimacyCard.fromDbRow).toList());
  }

  Future<List<Map<String, Object?>>> _queryCustomOnly(Database db) {
    return db.query(
      'cards',
      where: 'is_custom = 1 AND enabled = 1',
      orderBy: 'created_at DESC',
    );
  }

  Future<List<IntimacyCard>> _attachPoolLevels(
    Database db,
    List<IntimacyCard> cards,
  ) async {
    if (cards.isEmpty) return cards;
    final ids = cards.map((c) => c.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT card_id, level FROM card_pool_levels WHERE card_id IN ($placeholders)',
      ids,
    );
    final map = <String, List<int>>{};
    for (final r in rows) {
      final id = r['card_id'] as String;
      map.putIfAbsent(id, () => []).add(r['level'] as int);
    }
    return [
      for (final c in cards)
        c.copyWith(poolLevels: map[c.id] ?? (c.isCustom ? c.poolLevels : [c.level])),
    ];
  }

  /// 全部卡片（图鉴用，不含禁用）
  Future<List<IntimacyCard>> all() async {
    final db = await _db;
    final rows = await db.query('cards', where: 'enabled = 1');
    return _attachPoolLevels(
      db,
      rows.map(IntimacyCard.fromDbRow).toList(),
    );
  }

  /// 每个等级池各有多少张（含混入的自制卡）
  Future<Map<int, int>> countsByLevel() async {
    final db = await _db;
    final counts = <int, int>{};

    for (final lvl in AppConstants.levels) {
      if (lvl.level == AppConstants.customOnlyLevel) {
        final rows = await db.rawQuery(
          'SELECT COUNT(*) AS c FROM cards WHERE is_custom = 1 AND enabled = 1',
        );
        counts[lvl.level] = (rows.first['c'] as int?) ?? 0;
        continue;
      }

      final rows = await db.rawQuery('''
        SELECT COUNT(DISTINCT c.id) AS c
        FROM cards c
        LEFT JOIN card_pool_levels p ON c.id = p.card_id
        WHERE c.enabled = 1 AND (
          (c.is_custom = 0 AND c.level = ?)
          OR (c.is_custom = 1 AND p.level = ?)
        )
      ''', [lvl.level, lvl.level]);
      counts[lvl.level] = (rows.first['c'] as int?) ?? 0;
    }
    return counts;
  }

  Future<IntimacyCard?> byId(String id) async {
    final rows = await (await _db).query('cards', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final attached = await _attachPoolLevels(
      await _db,
      [IntimacyCard.fromDbRow(rows.first)],
    );
    return attached.first;
  }

  /// 全部自制卡（含禁用，供编辑器列表）
  Future<List<IntimacyCard>> customCards({bool includeDisabled = true}) async {
    final db = await _db;
    final rows = await db.query(
      'cards',
      where: 'is_custom = 1',
      whereArgs: const [],
      orderBy: 'created_at DESC',
    );
    final cards = rows.map(IntimacyCard.fromDbRow).toList();
    final withPools = await _attachPoolLevels(db, cards);
    if (includeDisabled) return withPools;
    return withPools.where((c) => c.enabled).toList();
  }

  Future<List<int>> poolLevelsFor(String cardId) async {
    final rows = await (await _db).query(
      'card_pool_levels',
      columns: ['level'],
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'level ASC',
    );
    return rows.map((r) => r['level'] as int).toList();
  }

  Future<void> _savePoolLevels(String cardId, List<int> levels) async {
    final db = await _db;
    await db.delete('card_pool_levels', where: 'card_id = ?', whereArgs: [cardId]);
    final batch = db.batch();
    for (final lv in levels.toSet()..remove(AppConstants.customOnlyLevel)) {
      if (lv >= 1 && lv <= 4) {
        batch.insert('card_pool_levels', {'card_id': cardId, 'level': lv});
      }
    }
    await batch.commit(noResult: true);
  }

  /// 用户自定义卡：批量导入
  Future<int> importCustomBatch(
    List<({IntimacyCard card, List<int> poolLevels})> items,
  ) async {
    if (items.isEmpty) return 0;
    final db = await _db;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'cards',
        item.card.toDbRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    for (final item in items) {
      await _savePoolLevels(item.card.id, item.poolLevels);
    }
    return items.length;
  }

  /// 用户自定义卡：新增
  Future<void> insertCustom(IntimacyCard card, {required List<int> poolLevels}) async {
    final db = await _db;
    await db.insert(
      'cards',
      card.toDbRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _savePoolLevels(card.id, poolLevels);
  }

  /// 用户自定义卡：更新
  Future<void> updateCustom(IntimacyCard card, {required List<int> poolLevels}) async {
    final db = await _db;
    await db.update(
      'cards',
      {
        'title': card.title,
        'description': card.description,
        'level': card.level,
        'rarity': card.rarity.code,
        'type': card.type,
        'tags': card.tags.join(','),
        'executor': card.executor.name,
        'duration': card.durationSeconds,
        'comfort_tags': card.comfortTags.join(','),
        'enabled': card.enabled ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
    await _savePoolLevels(card.id, poolLevels);
  }

  Future<void> deleteCustom(String id) async {
    final db = await _db;
    await db.delete('card_pool_levels', where: 'card_id = ?', whereArgs: [id]);
    await db.delete('cards', where: 'id = ? AND is_custom = 1', whereArgs: [id]);
  }

  /// 启停某张卡
  Future<void> setEnabled(String id, bool enabled) async {
    await (await _db).update(
      'cards',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FunctionCard>> functionCards() async {
    final rows = await (await _db).query('function_cards');
    return rows
        .map((r) => FunctionCard.fromJson({
              'id': r['id'],
              'title': r['title'],
              'description': r['description'],
              'rarity': r['rarity'],
              'effect': r['effect'],
            }))
        .toList();
  }
}
