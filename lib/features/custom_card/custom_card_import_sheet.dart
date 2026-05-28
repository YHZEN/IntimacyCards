import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/card_repository.dart';
import '../../shared/widgets/gold_button.dart';
import 'custom_card_importer.dart';

/// 粘贴 JSON 批量导入自制卡
class CustomCardImportSheet extends StatefulWidget {
  final CardRepository repo;

  const CustomCardImportSheet({super.key, required this.repo});

  static Future<int?> show(BuildContext context, {required CardRepository repo}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomCardImportSheet(repo: repo),
    );
  }

  @override
  State<CustomCardImportSheet> createState() => _CustomCardImportSheetState();
}

class _CustomCardImportSheetState extends State<CustomCardImportSheet> {
  final _jsonCtl = TextEditingController();
  bool _importing = false;
  bool _guideExpanded = true;

  @override
  void dispose() {
    _jsonCtl.dispose();
    super.dispose();
  }

  void _pasteExample() {
    HapticFeedback.selectionClick();
    _jsonCtl.text = CustomCardImporter.exampleJson.trim();
  }

  Future<void> _import() async {
    if (_importing) return;
    final raw = _jsonCtl.text.trim();
    if (raw.isEmpty) {
      _toast('请先粘贴 JSON 内容');
      return;
    }

    final parsed = CustomCardImporter.parse(raw);
    if (parsed.isEmpty) {
      _toast(parsed.errors.join('\n'));
      return;
    }

    setState(() => _importing = true);
    final count = await widget.repo.importCustomBatch(parsed.items);
    if (!mounted) return;

    setState(() => _importing = false);

    if (parsed.hasErrors) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('导入完成（部分警告）', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('成功导入 $count 张',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary)),
                if (parsed.errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('提示：', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  for (final e in parsed.errors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('· $e', style: AppTextStyles.bodySmall),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('好的'),
            ),
          ],
        ),
      );
    }

    if (mounted) Navigator.pop(context, count);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.bodySmall),
        backgroundColor: AppColors.surfaceAlt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return Container(
      height: maxH,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('导入卡片', style: AppTextStyles.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: _pasteExample,
                    icon: const Icon(Icons.content_paste, size: 16),
                    label: Text('填入示例', style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8 + bottom),
                children: [
                  _FormatGuideCard(
                    expanded: _guideExpanded,
                    onToggle: () =>
                        setState(() => _guideExpanded = !_guideExpanded),
                  ),
                  const SizedBox(height: 12),
                  Text('粘贴 JSON', style: AppTextStyles.caption),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: maxH * 0.28,
                      maxHeight: maxH * 0.38,
                    ),
                    child: TextField(
                      controller: _jsonCtl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        height: 1.45,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: '将 JSON 粘贴到此处…',
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primaryDim),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primaryDim),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GoldButton(
                          label: '取消',
                          primary: false,
                          onPressed:
                              _importing ? null : () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GoldButton(
                          label: _importing ? '导入中…' : '开始导入',
                          icon: Icons.file_download_outlined,
                          onPressed: _importing ? null : _import,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatGuideCard extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _FormatGuideCard({
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 18, color: AppColors.primary.withOpacity(0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('JSON 格式说明',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.primary)),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: AppColors.primaryDim.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CustomCardImporter.formatIntro,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.55),
                  ),
                  const SizedBox(height: 12),
                  Text('根结构（二选一）',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 6),
                  for (final f in CustomCardImporter.rootFormats)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                          children: [
                            TextSpan(
                              text: '${f.$1}：',
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            TextSpan(
                              text: f.$2,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontFamily: 'monospace',
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text('cards 内每张卡的字段',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 8),
                  ...CustomCardImporter.fieldRules.map(_fieldRow),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldRow(ImportFieldRule rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.primary,
                  height: 1.35,
                ),
                children: [
                  TextSpan(text: rule.name),
                  if (rule.required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.danger),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.desc, style: AppTextStyles.bodySmall),
                Text(
                  rule.example,
                  style: AppTextStyles.caption.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textDim,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
