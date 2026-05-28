import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/gold_button.dart';

/// 心愿卡（F09）输入弹层：输家向赢家提一个心愿替代本次任务。
class WishInputSheet extends StatefulWidget {
  const WishInputSheet({super.key});

  /// 返回值：用户写下的心愿；为 null 表示取消。
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WishInputSheet(),
    );
  }

  @override
  State<WishInputSheet> createState() => _WishInputSheetState();
}

class _WishInputSheetState extends State<WishInputSheet> {
  final _ctl = TextEditingController();
  bool get _ok => _ctl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.raritySSR;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: viewInsets),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: accent.withOpacity(0.55), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.28), blurRadius: 30),
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
                const SizedBox(height: 14),
                Text(
                  '✦  心愿卡  ✦',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(color: accent),
                ),
                const SizedBox(height: 6),
                Text(
                  '由输家向赢家提出一个心愿\n以心愿替代本次任务',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _ctl,
                  onChanged: (_) => setState(() {}),
                  maxLines: 3,
                  minLines: 3,
                  maxLength: 80,
                  style: AppTextStyles.bodyMedium,
                  cursorColor: accent,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '比如：今晚由你来给我洗头…',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textDim),
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
                      borderSide:
                          const BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
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
                      child: GoldButton(
                        label: '提出心愿',
                        icon: Icons.auto_awesome,
                        onPressed: _ok
                            ? () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context, _ctl.text.trim());
                              }
                            : null,
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
}
