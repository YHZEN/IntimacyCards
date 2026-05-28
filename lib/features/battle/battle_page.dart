import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/midnight_scaffold.dart';

class BattlePage extends ConsumerWidget {
  const BattlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('对战模式', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_kabaddi,
                  size: 64, color: AppColors.primaryDim),
              const SizedBox(height: 16),
              Text('对战模式开发中', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Text('石头剪刀布 / 色子 / 翻硬币 三选一',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
