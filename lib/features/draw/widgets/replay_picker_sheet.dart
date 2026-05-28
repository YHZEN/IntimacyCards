import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/card_rarity.dart';
import '../../../data/models/intimacy_card.dart';

/// 时光卡（F10）：从图鉴中已完成过的卡里挑一张重做。
class ReplayPickerSheet extends StatefulWidget {
  final List<IntimacyCard> candidates;

  const ReplayPickerSheet({super.key, required this.candidates});

  /// 返回用户选中的卡；null 表示取消。
  static Future<IntimacyCard?> show(
    BuildContext context, {
    required List<IntimacyCard> candidates,
  }) {
    return showModalBottomSheet<IntimacyCard>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReplayPickerSheet(candidates: candidates),
    );
  }

  @override
  State<ReplayPickerSheet> createState() => _ReplayPickerSheetState();
}

class _ReplayPickerSheetState extends State<ReplayPickerSheet> {
  int? _selectedIndex;

  IntimacyCard? get _selected =>
      _selectedIndex == null ? null : widget.candidates[_selectedIndex!];

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.raritySSR;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtl) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                  color: accent.withOpacity(0.55), width: 1.2),
            ),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.28), blurRadius: 30),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDim,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '✦  时光卡 · 重温收藏  ✦',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(color: accent),
                ),
                const SizedBox(height: 6),
                Text(
                  '挑一张曾经完成过的卡片，今晚再做一次',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtl,
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                    itemCount: widget.candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = widget.candidates[i];
                      final selected = _selectedIndex == i;
                      return _CardRow(
                        card: c,
                        selected: selected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedIndex = i);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            '取消',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _confirmButton(accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _confirmButton(Color accent) {
    final enabled = _selected != null;
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: enabled
          ? () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, _selected);
            }
          : null,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [accent, accent.withOpacity(0.7)],
                )
              : null,
          color: enabled ? null : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: enabled ? accent : AppColors.primaryDim,
            width: 1,
          ),
        ),
        child: Text(
          '重温',
          style: AppTextStyles.buttonPrimary.copyWith(
            color: enabled ? AppColors.bg : AppColors.textDim,
          ),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final IntimacyCard card;
  final bool selected;
  final VoidCallback onTap;

  const _CardRow({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = card.rarity.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.18)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : AppColors.primaryDim,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(card.rarity.code,
                  style: AppTextStyles.caption.copyWith(color: accent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: AppTextStyles.titleSmall.copyWith(color: accent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lv.${card.level} · ${card.description}',
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: accent, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
