import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/midnight_scaffold.dart';

class CustomCardPage extends ConsumerWidget {
  const CustomCardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('自制卡片', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_box_outlined,
                  size: 64, color: AppColors.primaryDim),
              const SizedBox(height: 16),
              Text('自制卡片编辑器开发中', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Text('完成后可写自己的卡片混入卡池',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
