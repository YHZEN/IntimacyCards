import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/intimacy_card.dart';

/// SQLite 数据库 · PRD §10.3
class AppDatabase {
  static const _dbName = 'intimacy_cards.db';
  static const _dbVersion = 1;
  static Database? _db;

  AppDatabase._();

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final String path;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      path = _dbName;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = p.join(dir.path, _dbName);
    }
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return _db!;
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        level INTEGER NOT NULL,
        rarity TEXT NOT NULL,
        type TEXT NOT NULL,
        tags TEXT,
        executor TEXT,
        duration INTEGER,
        comfort_tags TEXT,
        is_custom INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE function_cards (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        rarity TEXT NOT NULL,
        effect TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE couple_profile (
        id INTEGER PRIMARY KEY,
        my_name TEXT NOT NULL,
        partner_name TEXT NOT NULL,
        my_avatar TEXT NOT NULL,
        partner_avatar TEXT NOT NULL,
        anniversary TEXT NOT NULL,
        intimacy_level INTEGER DEFAULT 1,
        intimacy_exp INTEGER DEFAULT 0,
        safe_word TEXT DEFAULT '暂停',
        current_user TEXT DEFAULT 'self',
        excluded_comfort_tags TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE draws (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id TEXT NOT NULL,
        drawn_at TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        is_skipped INTEGER DEFAULT 0,
        is_battle INTEGER DEFAULT 0,
        executor_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id TEXT NOT NULL,
        mood TEXT,
        content TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        executor_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await _seedCards(db);
  }

  /// 从 assets/data/cards.json 写入预置卡牌
  static Future<void> _seedCards(Database db) async {
    final raw = await rootBundle.loadString('assets/data/cards.json');
    final data = json.decode(raw) as Map<String, dynamic>;

    final cards = (data['cards'] as List).cast<Map<String, dynamic>>();
    final batch = db.batch();
    for (final j in cards) {
      final card = IntimacyCard.fromJson(j);
      batch.insert('cards', card.toDbRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final fns = (data['functionCards'] as List).cast<Map<String, dynamic>>();
    for (final j in fns) {
      batch.insert('function_cards', {
        'id': j['id'],
        'title': j['title'],
        'description': j['description'],
        'rarity': j['rarity'],
        'effect': j['effect'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// 仅供测试 / 调试：清空并重新播种
  static Future<void> reseed() async {
    final db = await instance();
    await db.delete('cards');
    await db.delete('function_cards');
    await _seedCards(db);
  }
}
