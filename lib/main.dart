import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 强制竖屏（暗夜抽卡应用，无横屏需求）
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  // 状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 提前初始化 SQLite，触发 seed
  await AppDatabase.instance();

  runApp(const ProviderScope(child: IntimacyCardsApp()));
}
