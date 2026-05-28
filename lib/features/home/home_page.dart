import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/avatars.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/couple_profile.dart';
import '../../providers.dart';
import '../../router.dart';
import '../../shared/widgets/avatar_icon.dart';
import '../../shared/widgets/gold_button.dart';
import '../../shared/widgets/midnight_scaffold.dart';
import 'widgets/card_back_3d.dart';
import 'widgets/home_drawer.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(coupleProfileProvider);

    return MidnightScaffold(
      drawer: profileAsync.valueOrNull == null
          ? null
          : HomeDrawer(profile: profileAsync.value!),
      child: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
              child: Text('出错了：$e', style: AppTextStyles.bodyMedium)),
          data: (profile) {
            if (profile == null) return const SizedBox.shrink();
            return _HomeBody(profile: profile);
          },
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  final CoupleProfile profile;
  const _HomeBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _topBar(context),
                  const SizedBox(height: 4),
                  _coupleNames(),
                  const SizedBox(height: 4),
                  _daysTogether(),
                  const SizedBox(height: 20),
                  _intimacyBar(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: CardBack3D(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push(Routes.levelSelect);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _identityIndicator(context, ref),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GoldButton(
                      label: '开始抽卡',
                      icon: Icons.auto_awesome,
                      width: double.infinity,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push(Routes.levelSelect);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _navTiles(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: '菜单',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, color: AppColors.primary),
          ),
          const Spacer(),
          IconButton(
            tooltip: '设置',
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _coupleNames() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(profile.myName, style: AppTextStyles.titleLarge),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(Icons.favorite,
              color: AppColors.danger.withOpacity(0.85), size: 18),
        ),
        Text(profile.partnerName, style: AppTextStyles.titleLarge),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _daysTogether() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '── 在一起的第 ${profile.daysTogether} 天 ──',
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.textSecondary, letterSpacing: 4),
      ),
    );
  }

  Widget _intimacyBar() {
    final progress = profile.intimacyExp / 100.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('亲密度 Lv.${profile.intimacyLevel}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary, letterSpacing: 2)),
              Text('${(progress * 100).round()}%',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.danger],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _identityIndicator(BuildContext context, WidgetRef ref) {
    final avatar = Avatars.byId(profile.activeAvatar);
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await ref.read(coupleProfileProvider.notifier).switchUser();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.primaryDim),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarIcon(avatar: avatar, size: 16),
            const SizedBox(width: 8),
            Text('当前: ${profile.activeName}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            const Icon(Icons.swap_horiz,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('切换',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _navTiles(BuildContext context) {
    return Consumer(builder: (_, ref, __) {
      final counts = ref.watch(cardCountsProvider).valueOrNull ?? {};
      final collected = ref.watch(collectedCardIdsProvider).valueOrNull ?? {};
      final diaryCount = ref.watch(diaryCountProvider).valueOrNull ?? 0;
      final total = counts.values.fold<int>(0, (a, b) => a + b);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: _navTile(context,
                  icon: Icons.menu_book_outlined,
                  label: '图鉴',
                  sub: '${collected.length}/$total',
                  onTap: () => context.push(Routes.album)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _navTile(context,
                  icon: Icons.edit_note_outlined,
                  label: '日记',
                  sub: '$diaryCount 篇',
                  onTap: () => context.push(Routes.diary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _navTile(context,
                  icon: Icons.add_box_outlined,
                  label: '自制',
                  sub: '+',
                  onTap: () => context.push(Routes.customCard)),
            ),
          ],
        ),
      );
    });
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryDim),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 2),
            Text(sub, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
