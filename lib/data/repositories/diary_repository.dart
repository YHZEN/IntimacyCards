import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/card_rarity.dart';
import '../models/diary_entry.dart';

class DiaryRepository {
  Future<Database> get _db => AppDatabase.instance();

  Future<int> insert(DiaryEntry entry) async {
    return (await _db).insert('diary_entries', entry.toDbRow());
  }

  Future<List<DiaryEntry>> all() async {
    final rows = await (await _db).query(
      'diary_entries',
      orderBy: 'created_at DESC',
    );
    return rows.map(DiaryEntry.fromDbRow).toList();
  }

  /// 列表页用：JOIN cards 一次性带出卡片标题、稀有度、等级。
  Future<List<DiaryEntryView>> richEntries() async {
    final rows = await (await _db).rawQuery('''
      SELECT d.*,
             c.title  AS card_title,
             c.rarity AS card_rarity,
             c.level  AS card_level
      FROM diary_entries d
      LEFT JOIN cards c ON c.id = d.card_id
      ORDER BY d.created_at DESC
    ''');

    return rows.map((row) {
      final entry = DiaryEntry.fromDbRow(row);
      final rarityCode = row['card_rarity'] as String?;
      return DiaryEntryView(
        entry: entry,
        cardTitle: row['card_title'] as String?,
        cardRarity: rarityCode == null ? null : CardRarity.parse(rarityCode),
        cardLevel: row['card_level'] as int?,
      );
    }).toList();
  }

  Future<void> deleteById(int id) async {
    await (await _db).delete('diary_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final rows =
        await (await _db).rawQuery('SELECT COUNT(*) AS c FROM diary_entries');
    return (rows.first['c'] as int?) ?? 0;
  }
}
