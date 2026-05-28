import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/card_rarity.dart';
import '../../data/models/intimacy_card.dart';
import '../../providers.dart';
import '../../shared/widgets/midnight_scaffold.dart';

class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('卡牌图鉴', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: FutureBuilder<List<IntimacyCard>>(
          future: ref.read(cardRepoProvider).all(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final cards = snap.data!;
            final collected =
                ref.watch(collectedCardIdsProvider).valueOrNull ?? {};

            return Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  '收集进度  ${collected.length} / ${cards.length}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (_, i) {
                      final c = cards[i];
                      final got = collected.contains(c.id);
                      return _albumTile(c, got);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _albumTile(IntimacyCard card, bool collected) {
    final color = collected ? card.rarity.color : AppColors.textDim;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: collected ? color : AppColors.primaryDim,
        ),
        boxShadow: collected
            ? [
                BoxShadow(
                    color: color.withOpacity(0.3), blurRadius: 12),
              ]
            : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(card.rarity.code,
                style: AppTextStyles.caption.copyWith(color: color)),
          ),
          const Spacer(),
          Icon(
            collected ? Icons.favorite : Icons.lock_outline,
            color: color,
            size: 28,
          ),
          const Spacer(),
          Text(
            collected ? card.title : '？？？',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: collected ? AppColors.textPrimary : AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
