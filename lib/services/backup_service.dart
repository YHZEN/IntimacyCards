import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import '../data/database/app_database.dart';

/// 加密备份 / 恢复服务
///
/// - 导出：把 SQLite 中所有用户数据汇成一份 JSON，再用 AES-CBC + 用户输入的口令派生密钥加密，
///   打包成 base64 字符串，方便用户复制到任何笔记软件 / 云盘。
/// - 导入：反向解析，把数据库内容覆盖回去。
///
/// 注意：当前 MVP 把所有 6 张数据表（couple_profile / cards / function_cards /
/// draws / diary_entries / settings）整体导出、整体覆盖，不做版本兼容处理。
class BackupService {
  static const _magic = 'IC1'; // 文件格式标识
  static const _tables = [
    'couple_profile',
    'cards',
    'function_cards',
    'draws',
    'diary_entries',
    'settings',
  ];

  /// 把当前数据库导出为加密备份字符串。
  Future<String> export({required String passphrase}) async {
    assert(passphrase.length >= 4, '加密口令至少 4 位');
    final db = await AppDatabase.instance();

    final dump = <String, dynamic>{};
    for (final t in _tables) {
      dump[t] = await db.query(t);
    }
    final plain = jsonEncode({
      'magic': _magic,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': dump,
    });

    final key = _deriveKey(passphrase);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);

    return '$_magic:${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// 从加密备份字符串还原。
  ///
  /// 抛出 [BackupException] 表示口令错误 / 格式错误 / 数据损坏。
  Future<void> import({
    required String payload,
    required String passphrase,
  }) async {
    final parts = payload.trim().split(':');
    if (parts.length != 3 || parts[0] != _magic) {
      throw const BackupException('备份格式无效');
    }
    final IV iv;
    final String cipherB64;
    try {
      iv = IV(base64Decode(parts[1]));
      cipherB64 = parts[2];
    } catch (_) {
      throw const BackupException('备份格式无效');
    }

    final String plain;
    try {
      final encrypter =
          Encrypter(AES(_deriveKey(passphrase), mode: AESMode.cbc));
      plain = encrypter.decrypt(Encrypted.fromBase64(cipherB64), iv: iv);
    } catch (_) {
      throw const BackupException('口令不正确或备份已损坏');
    }

    final Map<String, dynamic> root;
    try {
      root = jsonDecode(plain) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('备份内容无法解析');
    }
    if (root['magic'] != _magic) {
      throw const BackupException('备份内容无法识别');
    }
    final data = root['data'] as Map<String, dynamic>;

    final db = await AppDatabase.instance();
    await db.transaction((txn) async {
      for (final t in _tables) {
        await txn.delete(t);
        final rows = (data[t] as List?) ?? const [];
        for (final r in rows) {
          await txn.insert(t, Map<String, Object?>.from(r as Map));
        }
      }
    });
  }

  /// 从口令派生 32 字节 AES key。
  ///
  /// 简化实现：UTF-8 字节循环填充至 32 字节。生产环境建议替换为 PBKDF2 / Argon2。
  Key _deriveKey(String passphrase) {
    final raw = utf8.encode(passphrase);
    if (raw.isEmpty) {
      throw const BackupException('口令不能为空');
    }
    final padded = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      padded[i] = raw[i % raw.length];
    }
    return Key(padded);
  }
}

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => message;
}
