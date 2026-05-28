import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/album/album_page.dart';
import 'features/battle/battle_page.dart';
import 'features/battle/pages/battle_flow_page.dart';
import 'features/battle/pages/battle_level_select_page.dart';
import 'features/custom_card/custom_card_page.dart';
import 'features/diary/diary_page.dart';
import 'features/draw/pages/draw_charging_page.dart';
import 'features/draw/pages/level_select_page.dart';
import 'features/home/home_page.dart';
import 'features/identity/identity_picker_page.dart';
import 'features/lock/lock_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/settings/settings_page.dart';

class Routes {
  Routes._();

  static const lock = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const identity = '/identity';
  static const levelSelect = '/draw/level';
  static const drawCharging = '/draw/charging';
  static const album = '/album';
  static const diary = '/diary';
  static const customCard = '/custom';
  static const settings = '/settings';
  static const battle = '/battle';
  static const battleLevel = '/battle/level';
  static const battleFlow = '/battle/flow';
}

final appRouter = GoRouter(
  initialLocation: Routes.lock,
  routes: [
    GoRoute(path: Routes.lock, builder: (_, __) => const LockPage()),
    GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingPage()),
    GoRoute(
      path: Routes.home,
      pageBuilder: (_, state) => _fade(state, const HomePage()),
    ),
    GoRoute(path: Routes.identity, builder: (_, __) => const IdentityPickerPage()),
    GoRoute(path: Routes.levelSelect, builder: (_, __) => const LevelSelectPage()),
    GoRoute(
      path: Routes.drawCharging,
      builder: (_, state) {
        final level = state.uri.queryParameters['level'];
        return DrawChargingPage(level: int.tryParse(level ?? '1') ?? 1);
      },
    ),
    GoRoute(path: Routes.album, builder: (_, __) => const AlbumPage()),
    GoRoute(path: Routes.diary, builder: (_, __) => const DiaryPage()),
    GoRoute(path: Routes.customCard, builder: (_, __) => const CustomCardPage()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsPage()),
    GoRoute(path: Routes.battle, builder: (_, __) => const BattlePage()),
    GoRoute(
      path: Routes.battleLevel,
      builder: (_, __) => const BattleLevelSelectPage(),
    ),
    GoRoute(
      path: Routes.battleFlow,
      builder: (_, state) {
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
        final rounds = int.tryParse(state.uri.queryParameters['rounds'] ?? '5') ?? 5;
        return BattleFlowPage(level: level, rounds: rounds);
      },
    ),
  ],
);

CustomTransitionPage<T> _fade<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}
