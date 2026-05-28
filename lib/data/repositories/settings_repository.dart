import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

/// `settings` 表的轻量 KV 封装。
///
/// 设计目标：跨会话持久化少量小状态（如保底计数、上次抽卡等级、
/// 今日跳过次数等），无需引入额外依赖（如 shared_preferences）。
class SettingsRepository {
  Future<Database> get _db => AppDatabase.instance();

  Future<String?> getString(String key) async {
    final rows = await (await _db).query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setString(String key, String value) async {
    await (await _db).insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getInt(String key) async {
    final v = await getString(key);
    if (v == null) return null;
    return int.tryParse(v);
  }

  Future<void> setInt(String key, int value) =>
      setString(key, value.toString());

  Future<void> remove(String key) async {
    await (await _db).delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
