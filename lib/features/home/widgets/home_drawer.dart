import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/avatars.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/couple_profile.dart';
import '../../../providers.dart';
import '../../../router.dart';
import '../../../shared/widgets/avatar_icon.dart';

/// 主页左上角菜单滑出抽屉：信息总览 + 各等级图鉴进度 + 快捷操作。
class HomeDrawer extends ConsumerWidget {
  final CoupleProfile profile;
  const HomeDrawer({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.bg,
      width: 320,
      child: SafeArea(
        child: Column(
          children: [
            _header(context, ref),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _statRow(ref),
                  const SizedBox(height: 16),
                  _levelProgress(ref),
                  const SizedBox(height: 8),
                  _divider(),
                  _menuItem(
                    context,
                    icon: Icons.sports_kabaddi,
                    label: '对战模式',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.battle);
                    },
                  ),
                  _divider(),
                  _menuItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    label: '图鉴',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.album);
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.edit_note_outlined,
                    label: '日记',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.diary);
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.add_box_outlined,
                    label: '自制卡片',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.customCard);
                    },
                  ),
                  _divider(),
                  _menuItem(
                    context,
                    icon: Icons.swap_horiz,
                    label: '切换身份',
                    trailing: Text(
                      profile.activeName,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await ref
                          .read(coupleProfileProvider.notifier)
                          .switchUser();
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.settings_outlined,
                    label: '设置',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.settings);
                    },
                  ),
                  _divider(),
                  _menuItem(
                    context,
                    icon: Icons.info_outline,
                    label: '关于',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  // ============ Sections ============

  Widget _header(BuildContext context, WidgetRef ref) {
    final mine = Avatars.byId(profile.myAvatar);
    final ta = Avatars.byId(profile.partnerAvatar);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.18),
            AppColors.accent.withOpacity(0.06),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.25)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _miniAvatar(mine),
              const SizedBox(width: 8),
              Icon(Icons.favorite,
                  size: 16,
                  color: AppColors.danger.withOpacity(0.85)),
              const SizedBox(width: 8),
              _miniAvatar(ta),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 20),
                tooltip: '关闭',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('${profile.myName}  ❤  ${profile.partnerName}',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            '在一起的第 ${profile.daysTogether} 天 · Lv.${profile.intimacyLevel}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _miniAvatar(PresetAvatar avatar) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: avatar.tint.withOpacity(0.5), width: 1.5),
      ),
      child: AvatarIcon(avatar: avatar, size: 18),
    );
  }

  Widget _statRow(WidgetRef ref) {
    final collected =
        ref.watch(collectedCardIdsProvider).valueOrNull?.length ?? 0;
    final totals = ref.watch(cardCountsProvider).valueOrNull ?? const {};
    final total = totals.values.fold<int>(0, (a, b) => a + b);
    final diary = ref.watch(diaryCountProvider).valueOrNull ?? 0;
    final draws = ref.watch(totalDrawsProvider).valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _statCell('已收集', '$collected / $total')),
          Expanded(child: _statCell('日记', '$diary 篇')),
          Expanded(child: _statCell('累计抽卡', '$draws 次')),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryDim),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.titleSmall
                  .copyWith(color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _levelProgress(WidgetRef ref) {
    final totals = ref.watch(cardCountsProvider).valueOrNull ?? const {};
    final collected =
        ref.watch(collectedCountsByLevelProvider).valueOrNull ?? const {};

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('图鉴进度',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary, letterSpacing: 3)),
          ),
          for (final lvl in AppConstants.levels)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _levelBar(
                lvl: lvl,
                got: collected[lvl.level] ?? 0,
                total: totals[lvl.level] ?? 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _levelBar({
    required LevelInfo lvl,
    required int got,
    required int total,
  }) {
    final color = switch (lvl.level) {
      1 => AppColors.level1,
      2 => AppColors.level2,
      3 => AppColors.level3,
      4 => AppColors.level4,
      5 => AppColors.level5,
      _ => AppColors.primary,
    };
    final pct = total == 0 ? 0.0 : (got / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(lvl.symbol, style: TextStyle(color: color, fontSize: 14)),
            const SizedBox(width: 6),
            Text('Lv.${lvl.level} ${lvl.name}',
                style:
                    AppTextStyles.bodySmall.copyWith(color: color)),
            const Spacer(),
            Text('$got / $total',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.6), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _divider() => Divider(
        color: AppColors.primaryDim,
        height: 24,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      );

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: trailing,
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text('IntimacyCards · 仅本地存储',
          style: AppTextStyles.caption),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    showAboutDialog(
      context: context,
      applicationName: 'IntimacyCards',
      applicationVersion: 'v0.1.0',
      applicationIcon: const Icon(Icons.favorite,
          color: AppColors.danger, size: 32),
      children: [
        const SizedBox(height: 8),
        Text('一款仅你和 TA 之间的私密抽卡 App。',
            style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        Text('全部数据仅本地存储，不上传任何云端。',
            style: AppTextStyles.bodySmall),
      ],
    );
  }
}
