import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/avatars.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/couple_profile.dart';
import '../../providers.dart';
import '../../router.dart';
import '../../services/security_service.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../../shared/widgets/gold_button.dart';
import '../../shared/widgets/midnight_scaffold.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;

  // Step 1
  final _myNameCtl = TextEditingController();
  final _partnerNameCtl = TextEditingController();
  String _myAvatarId = Avatars.all.first.id;
  String _partnerAvatarId = Avatars.all[1].id;

  // Step 2
  DateTime _anniversary = DateTime.now();

  // Step 3
  final Set<String> _excluded = {};

  // Step 4 - PIN
  final _pinCtl = TextEditingController();

  @override
  void dispose() {
    _myNameCtl.dispose();
    _partnerNameCtl.dispose();
    _pinCtl.dispose();
    super.dispose();
  }

  bool get _canNext {
    switch (_step) {
      case 0:
        return _myNameCtl.text.trim().isNotEmpty &&
            _partnerNameCtl.text.trim().isNotEmpty &&
            _myAvatarId != _partnerAvatarId;
      case 1:
        return true;
      case 2:
        return true;
      case 3:
        return _pinCtl.text.length == 4;
    }
    return false;
  }

  Future<void> _onNext() async {
    if (!_canNext) return;
    HapticFeedback.selectionClick();
    if (_step < 3) {
      setState(() => _step++);
      return;
    }

    // 最后一步：保存
    final profile = CoupleProfile(
      myName: _myNameCtl.text.trim(),
      partnerName: _partnerNameCtl.text.trim(),
      myAvatar: _myAvatarId,
      partnerAvatar: _partnerAvatarId,
      anniversary: _anniversary,
      excludedComfortTags: _excluded.toList(),
    );
    await ref.read(coupleProfileProvider.notifier).save(profile);
    await SecurityService().setMainPin(_pinCtl.text);

    if (!mounted) return;
    context.go(Routes.home);
  }

  void _onBack() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return MidnightScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _stepBody()),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          if (_step > 0)
            IconButton(
              onPressed: _onBack,
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.primary, size: 18),
            ),
          const Spacer(),
          Row(
            children: List.generate(4, (i) {
              final active = i <= _step;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 24 : 12,
                height: 4,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _step1Names();
      case 1:
        return _step2Anniversary();
      case 2:
        return _step3Comfort();
      case 3:
        return _step4Pin();
    }
    return const SizedBox.shrink();
  }

  Widget _stepTitle(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  // ---------- Step 1: 昵称 + 头像 ----------
  Widget _step1Names() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _stepTitle('从今天起，记录我们', '昵称与头像将在 App 全程沿用'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('你的昵称', style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              _nameField(_myNameCtl, '比如：小鹿'),
              const SizedBox(height: 16),
              Text('你的头像', style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              _avatarRow(selected: _myAvatarId, onPick: (id) {
                if (id == _partnerAvatarId) return;
                setState(() => _myAvatarId = id);
              }),
              const SizedBox(height: 32),
              Text('TA 的昵称', style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              _nameField(_partnerNameCtl, '比如：团子'),
              const SizedBox(height: 16),
              Text('TA 的头像', style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              _avatarRow(selected: _partnerAvatarId, onPick: (id) {
                if (id == _myAvatarId) return;
                setState(() => _partnerAvatarId = id);
              }),
              if (_myAvatarId == _partnerAvatarId)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('两人头像不能相同',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.danger)),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nameField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      maxLength: 8,
      style: AppTextStyles.bodyLarge,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyLarge.copyWith(color: AppColors.textDim),
        filled: true,
        fillColor: AppColors.surface,
        counterText: '',
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }

  Widget _avatarRow({required String selected, required ValueChanged<String> onPick}) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Avatars.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final a = Avatars.all[i];
          return AvatarBadge(
            avatar: a,
            size: 60,
            highlighted: a.id == selected,
            onTap: () => onPick(a.id),
          );
        },
      ),
    );
  }

  // ---------- Step 2: 纪念日 ----------
  Widget _step2Anniversary() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _stepTitle('我们的开始', '记下在一起的那一天'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _anniversary,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: AppColors.bg,
                      surface: AppColors.surface,
                      onSurface: AppColors.textPrimary,
                    ),
                    dialogTheme:
                        const DialogTheme(backgroundColor: AppColors.surface),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _anniversary = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryDim),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 16),
                  Text(
                    '${_anniversary.year} 年 ${_anniversary.month} 月 ${_anniversary.day} 日',
                    style: AppTextStyles.titleMedium,
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            '距今 ${DateTime.now().difference(_anniversary).inDays.abs() + 1} 天',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.accent, letterSpacing: 2),
          ),
        ),
      ],
    );
  }

  // ---------- Step 3: 舒适度 ----------
  static const _comfortTags = [
    ('outdoor', '户外场景'),
    ('food', '含食物'),
    ('mark', '留印记 / 吻痕'),
    ('cold', '冰块感官'),
    ('voice', '含录音'),
    ('photo', '含拍照'),
    ('alcohol', '含酒精'),
    ('restraint', '轻度约束'),
  ];

  Widget _step3Comfort() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _stepTitle('设定舒适边界', '勾选不想出现的内容，命中即从卡池排除'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 10,
            runSpacing: 12,
            children: _comfortTags.map((t) {
              final picked = _excluded.contains(t.$1);
              return GestureDetector(
                onTap: () => setState(() {
                  picked ? _excluded.remove(t.$1) : _excluded.add(t.$1);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: picked
                        ? AppColors.accent.withOpacity(0.3)
                        : AppColors.surface,
                    border: Border.all(
                      color: picked ? AppColors.accent : AppColors.primaryDim,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (picked)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.close,
                              size: 14, color: AppColors.accent),
                        ),
                      Text(t.$2,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: picked
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            '你以后随时可以在 设置 → 舒适度标签 中修改',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }

  // ---------- Step 4: 主密码 ----------
  Widget _step4Pin() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _stepTitle('设置启动密码', '4 位数字。下次进入这个秘密花园时使用'),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: TextField(
            controller: _pinCtl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.titleLarge.copyWith(letterSpacing: 18),
            cursorColor: AppColors.primary,
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: TextStyle(color: AppColors.textDim, letterSpacing: 12),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryDim, width: 1),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryDim, width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      child: GoldButton(
        label: _step < 3 ? '下一步' : '开启我们的故事',
        onPressed: _canNext ? _onNext : null,
        width: double.infinity,
      ),
    );
  }
}
