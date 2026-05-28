import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

/// 抽卡历史，主要用于图鉴的"已抽到"状态
class DrawRepository {
  Future<Database> get _db => AppDatabase.instance();

  Future<int> insert({
    required String cardId,
    required bool isCompleted,
    required bool isSkipped,
    required bool isBattle,
    required String executorName,
  }) async {
    return (await _db).insert('draws', {
      'card_id': cardId,
      'drawn_at': DateTime.now().toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'is_skipped': isSkipped ? 1 : 0,
      'is_battle': isBattle ? 1 : 0,
      'executor_name': executorName,
    });
  }

  /// 图鉴用："已收集"= 至少完成过一次（跳过不算）。
  Future<Set<String>> collectedCardIds() async {
    final rows = await (await _db).rawQuery(
      'SELECT DISTINCT card_id FROM draws WHERE is_completed = 1',
    );
    return {for (final r in rows) r['card_id'] as String};
  }
}
