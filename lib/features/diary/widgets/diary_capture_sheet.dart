import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/gold_button.dart';

/// 完成卡片后用于写日记的轻量底部弹层。
///
/// 返回值：
/// - `null`            ：用户跳过 / 关闭，不写日记
/// - `DiaryCaptureResult`：用户提交的心情 + 备注
///
/// 调用方负责把结果写入 `diary_entries` 表。
class DiaryCaptureResult {
  final String mood;
  final String content;
  const DiaryCaptureResult({required this.mood, required this.content});
}

class DiaryCaptureSheet extends StatefulWidget {
  final String cardTitle;
  final Color accentColor;

  const DiaryCaptureSheet({
    super.key,
    required this.cardTitle,
    required this.accentColor,
  });

  /// 便捷调用：返回 null 表示跳过 / 取消
  static Future<DiaryCaptureResult?> show(
    BuildContext context, {
    required String cardTitle,
    required Color accentColor,
  }) {
    return showModalBottomSheet<DiaryCaptureResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiaryCaptureSheet(
        cardTitle: cardTitle,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<DiaryCaptureSheet> createState() => _DiaryCaptureSheetState();
}

class _DiaryCaptureSheetState extends State<DiaryCaptureSheet> {
  static const _moods = ['😍', '🥰', '😊', '🥵', '🥺', '😂'];

  String _mood = '😍';
  final TextEditingController _contentCtl = TextEditingController();

  @override
  void dispose() {
    _contentCtl.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      DiaryCaptureResult(mood: _mood, content: _contentCtl.text.trim()),
    );
  }

  void _skip() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: viewInsets),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: accent.withOpacity(0.5), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.25), blurRadius: 30),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dragHandle(),
                const SizedBox(height: 14),
                Text(
                  '记下这一刻',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(color: accent),
                ),
                const SizedBox(height: 6),
                Text(
                  '为「${widget.cardTitle}」写下日记',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 22),
                _moodRow(accent),
                const SizedBox(height: 18),
                _contentField(accent),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '不记了',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GoldButton(
                        label: '保存',
                        icon: Icons.bookmark_added_outlined,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.primaryDim,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _moodRow(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _moods.map((emoji) {
        final selected = emoji == _mood;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _mood = emoji);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? accent.withOpacity(0.25)
                  : AppColors.surfaceAlt,
              border: Border.all(
                color: selected ? accent : AppColors.primaryDim,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.45),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        );
      }).toList(),
    );
  }

  Widget _contentField(Color accent) {
    return TextField(
      controller: _contentCtl,
      maxLines: 3,
      minLines: 3,
      maxLength: 200,
      style: AppTextStyles.bodyMedium,
      cursorColor: accent,
      decoration: InputDecoration(
        hintText: '今晚的感觉、TA 的反应、想保留的小细节… (可选)',
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textDim),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        counterStyle: AppTextStyles.caption,
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
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }
}
