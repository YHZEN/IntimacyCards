import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/couple_profile.dart';

class CoupleRepository {
  Future<Database> get _db => AppDatabase.instance();

  /// 读取唯一的情侣信息行
  Future<CoupleProfile?> load() async {
    final rows = await (await _db).query('couple_profile', where: 'id = 1');
    if (rows.isEmpty) return null;
    return CoupleProfile.fromDbRow(rows.first);
  }

  /// 保存（首次插入或更新）
  Future<void> save(CoupleProfile profile) async {
    await (await _db).insert(
      'couple_profile',
      profile.toDbRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> exists() async {
    return (await load()) != null;
  }

  Future<void> setCurrentUser(CurrentUser user) async {
    final profile = await load();
    if (profile == null) return;
    await save(profile.copyWith(currentUser: user));
  }

  Future<void> addIntimacyExp(int exp) async {
    final profile = await load();
    if (profile == null) return;
    var newExp = profile.intimacyExp + exp;
    var newLevel = profile.intimacyLevel;
    // 简单升级算法：每 100 经验升 1 级
    while (newExp >= 100) {
      newExp -= 100;
      newLevel++;
    }
    await save(profile.copyWith(intimacyExp: newExp, intimacyLevel: newLevel));
  }
}
