import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/card_rarity.dart';
import '../../data/models/diary_entry.dart';
import '../../providers.dart';
import '../../shared/widgets/midnight_scaffold.dart';

/// 完成日记 · PRD §5.7
///
/// 按日期分组展示日记条目；长按可删除。
class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntries = ref.watch(diaryEntriesProvider);

    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('完成日记', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: asyncEntries.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text('出错了：$e', style: AppTextStyles.bodyMedium),
          ),
          data: (entries) {
            if (entries.isEmpty) return const _EmptyState();
            return _DiaryList(entries: entries);
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note_outlined,
              size: 64, color: AppColors.primaryDim),
          const SizedBox(height: 16),
          Text('还没有日记', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text('完成一张卡片后选择"保存"\n这里会自动记录你们的故事',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _DiaryList extends ConsumerWidget {
  final List<DiaryEntryView> entries;
  const _DiaryList({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = _groupByDate(entries);
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: keys.length,
      itemBuilder: (_, sectionIndex) {
        final date = keys[sectionIndex];
        final dayEntries = groups[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(date),
            for (int i = 0; i < dayEntries.length; i++)
              _DiaryCard(
                view: dayEntries[i],
                onDelete: () => _confirmDelete(context, ref, dayEntries[i]),
              ).animate().fadeIn(
                    duration: 320.ms,
                    delay: (i * 60).ms,
                  ).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDateHeader(date),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.primary, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  /// 不依赖 intl 的中文 locale 数据，直接手写"星期 X"。
  String _formatDateHeader(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final yesterday = today.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    final prefix = isToday
        ? '今天'
        : isYesterday
            ? '昨天'
            : '星期${weekdays[date.weekday - 1]}';

    return '${date.year} 年 ${date.month} 月 ${date.day} 日 · $prefix';
  }

  Map<DateTime, List<DiaryEntryView>> _groupByDate(
    List<DiaryEntryView> entries,
  ) {
    final map = <DateTime, List<DiaryEntryView>>{};
    for (final e in entries) {
      final d = e.entry.createdAt;
      final dayKey = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(dayKey, () => []).add(e);
    }
    return map;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DiaryEntryView view,
  ) async {
    HapticFeedback.selectionClick();
    final id = view.entry.id;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('删除这条日记？', style: AppTextStyles.titleMedium),
        content: Text(
          '删除后无法找回。卡片在图鉴中的收集状态保留。',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await ref.read(diaryRepoProvider).deleteById(id);
    ref.invalidate(diaryEntriesProvider);
    ref.invalidate(diaryCountProvider);
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntryView view;
  final VoidCallback onDelete;

  const _DiaryCard({required this.view, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final entry = view.entry;
    final rarity = view.cardRarity ?? CardRarity.r;
    final accent = rarity.color;
    final timeText = DateFormat('HH:mm').format(entry.createdAt);
    final title = view.cardTitle ?? '（卡片已删除）';

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.15), blurRadius: 14),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (entry.mood.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(entry.mood,
                        style: const TextStyle(fontSize: 22)),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(color: accent),
                  ),
                ),
                _rarityChip(rarity),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(timeText,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDim)),
                if (entry.executorName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('·', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  Text(entry.executorName, style: AppTextStyles.caption),
                ],
                if (view.cardLevel != null) ...[
                  const SizedBox(width: 8),
                  Text('·', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  Text('Lv.${view.cardLevel}', style: AppTextStyles.caption),
                ],
              ],
            ),
            if (entry.content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                entry.content,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rarityChip(CardRarity rarity) {
    final color = rarity.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(rarity.code,
          style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}
