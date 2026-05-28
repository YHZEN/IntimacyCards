import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/intimacy_card.dart';
import '../../providers.dart';
import '../../shared/widgets/gold_button.dart';
import '../../shared/widgets/midnight_scaffold.dart';
import 'custom_card_editor_sheet.dart';
import 'custom_card_import_sheet.dart';

class CustomCardPage extends ConsumerWidget {
  const CustomCardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(customCardsProvider);

    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('自制卡片', style: AppTextStyles.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '导入 JSON',
            icon: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
            onPressed: () => _openImport(context, ref),
          ),
          IconButton(
            tooltip: '新建',
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _openEditor(context, ref),
          ),
        ],
      ),
      child: SafeArea(
        child: cardsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (cards) {
            if (cards.isEmpty) return _emptyState(context, ref);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    '共 ${cards.length} 张 · 全部会进入「定制的爱」',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary, letterSpacing: 1),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CustomCardTile(
                      card: cards[i],
                      onEdit: () => _openEditor(context, ref, existing: cards[i]),
                      onToggle: () async {
                        await ref
                            .read(cardRepoProvider)
                            .setEnabled(cards[i].id, !cards[i].enabled);
                        ref.invalidate(customCardsProvider);
                        ref.invalidate(cardCountsProvider);
                      },
                      onDelete: () => _confirmDelete(context, ref, cards[i]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bg,
        icon: const Icon(Icons.edit_note),
        label: Text('写新卡', style: AppTextStyles.buttonPrimary),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 56, color: AppColors.primaryDim),
            const SizedBox(height: 16),
            Text('还没有自制卡', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              '写下只属于你俩的任务，可混入 Lv.1–4 或仅在「定制的爱」中抽取',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            GoldButton(
              label: '写第一张',
              icon: Icons.add,
              onPressed: () => _openEditor(context, ref),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _openImport(context, ref),
              icon: const Icon(Icons.file_upload_outlined,
                  size: 18, color: AppColors.primary),
              label: Text('或导入 JSON 批量添加',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openImport(BuildContext context, WidgetRef ref) async {
    final count = await CustomCardImportSheet.show(
      context,
      repo: ref.read(cardRepoProvider),
    );
    if (count != null && count > 0) {
      ref.invalidate(customCardsProvider);
      ref.invalidate(cardCountsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已导入 $count 张自制卡', style: AppTextStyles.bodySmall),
            backgroundColor: AppColors.surfaceAlt,
          ),
        );
      }
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    IntimacyCard? existing,
  }) async {
    final ok = await CustomCardEditorSheet.show(
      context,
      repo: ref.read(cardRepoProvider),
      existing: existing,
    );
    if (ok == true) {
      ref.invalidate(customCardsProvider);
      ref.invalidate(cardCountsProvider);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    IntimacyCard card,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('删除这张卡？', style: AppTextStyles.titleMedium),
        content: Text('「${card.title}」将被永久删除',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(cardRepoProvider).deleteCustom(card.id);
      ref.invalidate(customCardsProvider);
      ref.invalidate(cardCountsProvider);
    }
  }
}

class _CustomCardTile extends StatelessWidget {
  final IntimacyCard card;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CustomCardTile({
    required this.card,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: card.enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: card.rarity.color.withOpacity(0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: card.rarity.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    card.rarity.code,
                    style: AppTextStyles.caption
                        .copyWith(color: card.rarity.color, letterSpacing: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(card.title, style: AppTextStyles.titleSmall),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      color: AppColors.textSecondary, size: 20),
                  color: AppColors.surfaceAlt,
                  onSelected: (v) {
                    HapticFeedback.selectionClick();
                    switch (v) {
                      case 'edit':
                        onEdit();
                      case 'toggle':
                        onToggle();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(card.enabled ? '停用' : '启用'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              _poolLabel(),
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  String _poolLabel() {
    if (card.poolLevels.isEmpty) {
      return '✎ 仅「定制的爱」';
    }
    final parts = card.poolLevels.map((l) => 'Lv.$l').join(' · ');
    return '✎ 定制的爱 + 混入 $parts';
  }
}
