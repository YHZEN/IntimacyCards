import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/intimacy_card.dart';

class CardRepository {
  Future<Database> get _db => AppDatabase.instance();

  /// 按等级查询卡片
  Future<List<IntimacyCard>> byLevel(int level) async {
    final rows = await (await _db).query(
      'cards',
      where: 'level = ? AND enabled = 1',
      whereArgs: [level],
    );
    return rows.map(IntimacyCard.fromDbRow).toList();
  }

  /// 全部卡片
  Future<List<IntimacyCard>> all() async {
    final rows = await (await _db).query('cards', where: 'enabled = 1');
    return rows.map(IntimacyCard.fromDbRow).toList();
  }

  /// 每个等级各有多少张
  Future<Map<int, int>> countsByLevel() async {
    final rows = await (await _db).rawQuery(
      'SELECT level, COUNT(*) AS c FROM cards WHERE enabled = 1 GROUP BY level',
    );
    return {
      for (final r in rows) r['level'] as int: r['c'] as int,
    };
  }

  Future<IntimacyCard?> byId(String id) async {
    final rows = await (await _db).query('cards', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return IntimacyCard.fromDbRow(rows.first);
  }

  /// 用户自定义卡：新增
  Future<void> insertCustom(IntimacyCard card) async {
    await (await _db).insert(
      'cards',
      card.toDbRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
