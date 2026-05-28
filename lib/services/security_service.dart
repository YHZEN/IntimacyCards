import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 密码与安全存储 · PRD §9
///
/// 使用系统级 Keychain / Keystore 存储 PIN 等敏感信息。
class SecurityService {
  static const _storage = FlutterSecureStorage();

  static const _kMainPin = 'main_pin';
  static const _kLv4Pin = 'lv4_pin';
  static const _kFailedAttempts = 'failed_attempts';

  // ----- 主密码 -----
  Future<bool> hasMainPin() async => (await _storage.read(key: _kMainPin)) != null;

  Future<void> setMainPin(String pin) async {
    assert(pin.length == 4 && int.tryParse(pin) != null, '主密码必须是 4 位数字');
    await _storage.write(key: _kMainPin, value: pin);
    await resetFailedAttempts();
  }

  Future<bool> verifyMainPin(String pin) async {
    final saved = await _storage.read(key: _kMainPin);
    if (saved == null) return false;
    final ok = saved == pin;
    if (ok) {
      await resetFailedAttempts();
    } else {
      await _incFailedAttempts();
    }
    return ok;
  }

  // ----- Lv.4 独立密码 -----
  Future<bool> hasLv4Pin() async => (await _storage.read(key: _kLv4Pin)) != null;

  Future<void> setLv4Pin(String pin) async {
    assert(pin.length == 6 && int.tryParse(pin) != null, 'Lv.4 密码必须是 6 位数字');
    await _storage.write(key: _kLv4Pin, value: pin);
  }

  Future<bool> verifyLv4Pin(String pin) async {
    final saved = await _storage.read(key: _kLv4Pin);
    return saved == pin;
  }

  /// 清除 Lv.4 独立密码（关闭 Lv.4 入口）。
  static Future<void> clearLv4Pin() async {
    await _storage.delete(key: _kLv4Pin);
  }

  // ----- 失败计数（PRD §5.1：错 5 次伪装）-----
  Future<int> failedAttempts() async {
    final v = await _storage.read(key: _kFailedAttempts);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<void> _incFailedAttempts() async {
    final n = await failedAttempts();
    await _storage.write(key: _kFailedAttempts, value: '${n + 1}');
  }

  Future<void> resetFailedAttempts() async {
    await _storage.write(key: _kFailedAttempts, value: '0');
  }

  /// 清空所有安全数据（解绑设备、重置等场景）
  Future<void> wipe() async {
    await _storage.deleteAll();
  }
}
