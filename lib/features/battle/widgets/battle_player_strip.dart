import 'package:flutter/material.dart';

import '../../../core/constants/avatars.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/couple_profile.dart';
import '../../../shared/widgets/avatar_badge.dart';
import '../models/battle_models.dart';

/// 对战双方信息条 · 顶部横向排列，文字不翻转
class BattlePlayerStrip extends StatelessWidget {
  final CoupleProfile profile;
  final BattleSide? activeSide;
  final BattleSide? winnerSide;
  final Map<BattleSide, int> scores;

  const BattlePlayerStrip({
    super.key,
    required this.profile,
    this.activeSide,
    this.winnerSide,
    this.scores = const {},
  });

  @override
  Widget build(BuildContext context) {
    final selfScore = scores[BattleSide.self] ?? 0;
    final partnerScore = scores[BattleSide.partner] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDim),
      ),
      child: Row(
        children: [
          Expanded(
            child: _playerTile(
              side: BattleSide.self,
              name: profile.myName,
              avatar: Avatars.byId(profile.myAvatar),
              score: selfScore,
              alignEnd: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Text(
                  'VS',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activeSide != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _playerTile(
              side: BattleSide.partner,
              name: profile.partnerName,
              avatar: Avatars.byId(profile.partnerAvatar),
              score: partnerScore,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerTile({
    required BattleSide side,
    required String name,
    required PresetAvatar avatar,
    required int score,
    required bool alignEnd,
  }) {
    final isActive = activeSide == side;
    final isWinner = winnerSide == side;

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[
          AvatarBadge(
            avatar: avatar,
            size: 40,
            highlighted: isActive || isWinner,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isActive ? AppColors.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (isWinner) ...[
                    const SizedBox(width: 4),
                    Text('✦',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary)),
                  ],
                  if (isActive && !isWinner) ...[
                    const SizedBox(width: 6),
                    Text(
                      '轮到',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: 8),
          AvatarBadge(
            avatar: avatar,
            size: 40,
            highlighted: isActive || isWinner,
          ),
        ],
      ],
    );
  }
}
