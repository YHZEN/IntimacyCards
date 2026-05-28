import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/avatars.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/couple_profile.dart';
import '../../../shared/widgets/avatar_badge.dart';
import '../../../shared/widgets/gold_button.dart';
import '../models/battle_models.dart';

/// 同机防偷看过渡页 · PRD §8.3
///
/// 全屏遮罩 + "把手机递给 TA" + 身份确认按钮。
class PassPhoneGate extends StatelessWidget {
  final CoupleProfile profile;
  final BattleSide expectedSide;
  final VoidCallback onConfirmed;

  const PassPhoneGate({
    super.key,
    required this.profile,
    required this.expectedSide,
    required this.onConfirmed,
  });

  static Future<void> show(
    BuildContext context, {
    required CoupleProfile profile,
    required BattleSide expectedSide,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      builder: (ctx) => PassPhoneGate(
        profile: profile,
        expectedSide: expectedSide,
        onConfirmed: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetName = expectedSide.name(profile);
    final avatar = Avatars.byId(expectedSide.avatarId(profile));
    final selfAvatar = Avatars.byId(
      expectedSide == BattleSide.self
          ? profile.myAvatar
          : profile.partnerAvatar,
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(Icons.phonelink_ring_outlined,
                    size: 48, color: AppColors.primary.withOpacity(0.7)),
                const SizedBox(height: 24),
                Text(
                  '把手机递给',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary, letterSpacing: 4),
                ),
                const SizedBox(height: 12),
                Text(
                  targetName,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.primary,
                    shadows: [
                      Shadow(
                        color: AppColors.primary.withOpacity(0.6),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AvatarBadge(avatar: avatar, size: 88, highlighted: true),
                const Spacer(flex: 3),
                Text(
                  '接过后点击下方确认身份',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 20),
                GoldButton(
                  label: '我是 $targetName',
                  icon: null,
                  width: double.infinity,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onConfirmed();
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '${selfAvatar.emoji}  请勿偷看对方的选择',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textDim),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
