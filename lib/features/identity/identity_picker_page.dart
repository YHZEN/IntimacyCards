import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/avatars.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/couple_profile.dart';
import '../../providers.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../../shared/widgets/midnight_scaffold.dart';

/// 单人抽卡前的轻量"我是谁"选择 · PRD §5.4
///
/// 用户从主页"开始抽卡"进入；当主页指示器已是目标身份时，
/// 上层路由会跳过这个页面直接进入等级选择。
class IdentityPickerPage extends ConsumerWidget {
  const IdentityPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(coupleProfileProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final my = Avatars.byId(profile.myAvatar);
    final partner = Avatars.byId(profile.partnerAvatar);

    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('谁来抽这一张', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _identityCard(
                    context,
                    ref,
                    name: profile.myName,
                    avatar: my,
                    selected: profile.currentUser == CurrentUser.self,
                    targetUser: CurrentUser.self,
                  ),
                  _identityCard(
                    context,
                    ref,
                    name: profile.partnerName,
                    avatar: partner,
                    selected: profile.currentUser == CurrentUser.partner,
                    targetUser: CurrentUser.partner,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('点击头像选择身份',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 6),
              Text('后续可在主页一键切换',
                  style: AppTextStyles.caption),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityCard(
    BuildContext context,
    WidgetRef ref, {
    required String name,
    required PresetAvatar avatar,
    required bool selected,
    required CurrentUser targetUser,
  }) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await ref
            .read(coupleRepoProvider)
            .setCurrentUser(targetUser);
        ref.invalidate(coupleProfileProvider);
        if (context.mounted) context.pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.primaryDim,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AvatarBadge(avatar: avatar, size: 80, highlighted: selected),
            const SizedBox(height: 16),
            Text(name, style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            if (selected)
              Text('✓ 上次',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
