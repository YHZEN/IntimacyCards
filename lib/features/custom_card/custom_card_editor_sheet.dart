import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/card_rarity.dart';
import '../../data/models/intimacy_card.dart';
import '../../data/repositories/card_repository.dart';
import '../../shared/widgets/gold_button.dart';

/// 自制卡编辑 / 新建表单
class CustomCardEditorSheet extends StatefulWidget {
  final CardRepository repo;
  final IntimacyCard? existing;

  const CustomCardEditorSheet({
    super.key,
    required this.repo,
    this.existing,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CardRepository repo,
    IntimacyCard? existing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomCardEditorSheet(repo: repo, existing: existing),
    );
  }

  @override
  State<CustomCardEditorSheet> createState() => _CustomCardEditorSheetState();
}

class _CustomCardEditorSheetState extends State<CustomCardEditorSheet> {
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  CardRarity _rarity = CardRarity.r;
  CardExecutor _executor = CardExecutor.loser;
  final Set<int> _poolLevels = {};
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtl.text = e.title;
      _descCtl.text = e.description;
      _rarity = e.rarity;
      _executor = e.executor;
      _poolLevels.addAll(e.poolLevels.where((l) => l >= 1 && l <= 4));
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtl.text.trim();
    final desc = _descCtl.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请填写卡名和描述', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.surfaceAlt,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final pools = _poolLevels.toList()..sort();
    final primaryLevel = pools.isNotEmpty
        ? pools.first
        : AppConstants.customOnlyLevel;

    final card = (widget.existing ??
            IntimacyCard(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
              title: title,
              description: desc,
              level: primaryLevel,
              rarity: _rarity,
              type: 'action',
              tags: const ['custom'],
              executor: _executor,
              isCustom: true,
            ))
        .copyWith(
      title: title,
      description: desc,
      level: primaryLevel,
      rarity: _rarity,
      executor: _executor,
      poolLevels: pools,
    );

    if (_isEdit) {
      await widget.repo.updateCustom(card, poolLevels: pools);
    } else {
      await widget.repo.insertCustom(card, poolLevels: pools);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEdit ? '编辑自制卡' : '写一张新卡',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field('卡名', _titleCtl, maxLines: 1, hint: '例如：专属的晚安吻'),
                      const SizedBox(height: 14),
                      _field('任务描述', _descCtl, maxLines: 4, hint: '写清楚要做什么…'),
                      const SizedBox(height: 20),
                      Text('稀有度', style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      _rarityRow(),
                      const SizedBox(height: 20),
                      Text('执行者', style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      _executorRow(),
                      const SizedBox(height: 20),
                      Text('混入等级池（可多选）', style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      Text(
                        '不选则仅在「定制的爱」中抽取；选中后会同时混入对应等级',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      _poolLevelRow(),
                      const SizedBox(height: 24),
                      GoldButton(
                        label: _saving ? '保存中…' : '保存卡片',
                        icon: Icons.favorite,
                        width: double.infinity,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctl, {
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 6),
        TextField(
          controller: ctl,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryDim),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryDim),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rarityRow() {
    return Row(
      children: [
        for (final r in [CardRarity.r, CardRarity.sr, CardRarity.ssr])
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: r != CardRarity.ssr ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _rarity = r);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _rarity == r
                        ? r.color.withOpacity(0.2)
                        : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _rarity == r ? r.color : AppColors.primaryDim,
                      width: _rarity == r ? 1.8 : 1,
                    ),
                  ),
                  child: Text(
                    r.code,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleSmall.copyWith(color: r.color),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _executorRow() {
    const options = [
      (CardExecutor.loser, '输家 / 抽卡方'),
      (CardExecutor.winner, '赢家'),
      (CardExecutor.both, '两人一起'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          FilterChip(
            label: Text(o.$2, style: AppTextStyles.bodySmall),
            selected: _executor == o.$1,
            onSelected: (_) => setState(() => _executor = o.$1),
            selectedColor: AppColors.primary.withOpacity(0.25),
            checkmarkColor: AppColors.primary,
            side: BorderSide(
              color: _executor == o.$1
                  ? AppColors.primary
                  : AppColors.primaryDim,
            ),
          ),
      ],
    );
  }

  Widget _poolLevelRow() {
    final mixLevels =
        AppConstants.levels.where((l) => l.level >= 1 && l.level <= 4);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final lvl in mixLevels)
          FilterChip(
            label: Text('Lv.${lvl.level} ${lvl.name}',
                style: AppTextStyles.bodySmall),
            selected: _poolLevels.contains(lvl.level),
            onSelected: (on) {
              HapticFeedback.selectionClick();
              setState(() {
                if (on) {
                  _poolLevels.add(lvl.level);
                } else {
                  _poolLevels.remove(lvl.level);
                }
              });
            },
            selectedColor: _levelChipColor(lvl.level).withOpacity(0.25),
            checkmarkColor: _levelChipColor(lvl.level),
            side: BorderSide(
              color: _poolLevels.contains(lvl.level)
                  ? _levelChipColor(lvl.level)
                  : AppColors.primaryDim,
            ),
          ),
      ],
    );
  }

  Color _levelChipColor(int level) => switch (level) {
        1 => AppColors.level1,
        2 => AppColors.level2,
        3 => AppColors.level3,
        4 => AppColors.level4,
        _ => AppColors.primary,
      };
}
