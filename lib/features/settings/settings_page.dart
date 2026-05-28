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
import '../../services/backup_service.dart';
import '../../services/security_service.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../../shared/widgets/gold_button.dart';
import '../../shared/widgets/midnight_scaffold.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(coupleProfileProvider).valueOrNull;

    return MidnightScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('设置', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _section('情侣信息'),
            _tile(
              icon: Icons.favorite_outline,
              title: profile == null
                  ? '未设置'
                  : '${profile.myName} ❤ ${profile.partnerName}',
              subtitle: profile == null
                  ? null
                  : '在一起的第 ${profile.daysTogether} 天',
              onTap: profile == null
                  ? null
                  : () => _editCouple(context, ref, profile),
            ),
            _tile(
              icon: Icons.shield_moon_outlined,
              title: '安全词',
              subtitle: profile?.safeWord ?? '暂停',
              onTap: profile == null
                  ? null
                  : () => _editSafeWord(context, ref, profile),
            ),
            const SizedBox(height: 16),
            _section('安全'),
            _tile(
              icon: Icons.lock_outline,
              title: '修改主密码',
              subtitle: '4 位数字 · 启动时使用',
              onTap: () => _changeMainPin(context),
            ),
            _tile(
              icon: Icons.no_adult_content_outlined,
              title: 'Lv.4 独立密码',
              subtitle: '专用于解锁 18+ 内容',
              onTap: () => _manageLv4Pin(context),
            ),
            _tile(
              icon: Icons.theater_comedy_outlined,
              title: '伪装图标',
              subtitle: '让 App 看起来像计算器 / 备忘录',
              onTap: () => _showDecoyNotice(context),
            ),
            const SizedBox(height: 16),
            _section('数据'),
            _tile(
              icon: Icons.cloud_download_outlined,
              title: '导出加密备份',
              subtitle: '使用口令加密所有数据',
              onTap: () => _exportBackup(context),
            ),
            _tile(
              icon: Icons.cloud_upload_outlined,
              title: '导入备份',
              subtitle: '粘贴备份字符串恢复',
              onTap: () => _importBackup(context, ref),
            ),
            _tile(
              icon: Icons.restart_alt,
              title: '重置（清空所有数据）',
              destructive: true,
              onTap: () => _confirmReset(context),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text('IntimacyCards · v0.1.0\n仅本地存储 · 不上传任何数据',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ====================== 情侣信息 ======================
  Future<void> _editCouple(
    BuildContext context,
    WidgetRef ref,
    CoupleProfile profile,
  ) async {
    final updated = await showModalBottomSheet<CoupleProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditCoupleSheet(profile: profile),
    );
    if (updated != null) {
      await ref.read(coupleProfileProvider.notifier).save(updated);
      if (context.mounted) {
        _toast(context, '已保存');
      }
    }
  }

  Future<void> _editSafeWord(
    BuildContext context,
    WidgetRef ref,
    CoupleProfile profile,
  ) async {
    final ctl = TextEditingController(text: profile.safeWord);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('修改安全词', style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('在游戏中说出此词意味着立即停止当前任务。',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: ctl,
              autofocus: true,
              maxLength: 12,
              style: AppTextStyles.bodyLarge,
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '比如：暂停 / 红灯 / 喵',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final v = ctl.text.trim();
              if (v.isEmpty) return;
              Navigator.pop(ctx, v);
            },
            child: Text('保存',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (result != null && result != profile.safeWord) {
      await ref
          .read(coupleProfileProvider.notifier)
          .save(profile.copyWith(safeWord: result));
      if (context.mounted) _toast(context, '安全词已更新');
    }
  }

  // ====================== 安全 / 密码 ======================
  Future<void> _changeMainPin(BuildContext context) async {
    final security = SecurityService();
    final hasPin = await security.hasMainPin();
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PinChangeDialog(
        title: '修改主密码',
        digits: 4,
        requireOld: hasPin,
        verifyOld: security.verifyMainPin,
        onConfirm: (pin) async {
          await security.setMainPin(pin);
          return true;
        },
      ),
    );
    if (ok == true && context.mounted) _toast(context, '主密码已更新');
  }

  Future<void> _manageLv4Pin(BuildContext context) async {
    final security = SecurityService();
    final hasPin = await security.hasLv4Pin();
    if (!context.mounted) return;

    if (!hasPin) {
      // 未设置：直接走"设置新密码"
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _PinChangeDialog(
          title: '设置 Lv.4 密码',
          digits: 6,
          requireOld: false,
          verifyOld: security.verifyLv4Pin,
          onConfirm: (pin) async {
            await security.setLv4Pin(pin);
            return true;
          },
        ),
      );
      if (ok == true && context.mounted) _toast(context, 'Lv.4 密码已设置');
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.password, color: AppColors.primary),
              title: Text('修改密码', style: AppTextStyles.bodyLarge),
              onTap: () => Navigator.pop(ctx, 'change'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('清除密码（关闭 Lv.4 入口）',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.danger)),
              onTap: () => Navigator.pop(ctx, 'clear'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'change') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _PinChangeDialog(
          title: '修改 Lv.4 密码',
          digits: 6,
          requireOld: true,
          verifyOld: security.verifyLv4Pin,
          onConfirm: (pin) async {
            await security.setLv4Pin(pin);
            return true;
          },
        ),
      );
      if (ok == true && context.mounted) _toast(context, 'Lv.4 密码已更新');
    } else if (action == 'clear') {
      final confirm = await _confirmDialog(
        context,
        title: '清除 Lv.4 密码？',
        body: '清除后任何人都将不能再进入 Lv.4，下次进入会重新让你设置密码。',
        danger: true,
      );
      if (!context.mounted || !confirm) return;
      // 让用户先证明自己知道当前密码再清除
      final verified = await showDialog<bool>(
        context: context,
        builder: (ctx) => _PinVerifyDialog(
          title: '验证当前 Lv.4 密码',
          digits: 6,
          verify: security.verifyLv4Pin,
        ),
      );
      if (verified != true) return;
      await SecurityService.clearLv4Pin();
      if (context.mounted) _toast(context, 'Lv.4 密码已清除');
    }
  }

  Future<void> _showDecoyNotice(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('伪装图标 · 即将推出', style: AppTextStyles.titleMedium),
        content: Text(
          '为了让 App 在桌面上看起来像计算器 / 备忘录，我们需要原生构建支持：\n'
          '· iOS：Alternate Icons\n'
          '· Android：activity-alias\n\n'
          '当前 Web 预览版本不支持替换桌面图标。原生包构建后会在这里启用。',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('知道了',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ====================== 数据备份 / 还原 ======================
  Future<void> _exportBackup(BuildContext context) async {
    final passCtl = TextEditingController();
    final input = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          final canGo = passCtl.text.length >= 4;
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('生成加密备份', style: AppTextStyles.titleMedium),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('设置一个加密口令（≥ 4 位）。\n请妥善保管，丢失后无法恢复。',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtl,
                  onChanged: (_) => setState(() {}),
                  obscureText: true,
                  autofocus: true,
                  cursorColor: AppColors.primary,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(hintText: '加密口令'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('取消',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed:
                    canGo ? () => Navigator.pop(ctx, passCtl.text) : null,
                child: Text('生成',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          );
        });
      },
    );
    if (input == null || !context.mounted) return;

    String? payload;
    String? error;
    try {
      payload = await BackupService().export(passphrase: input);
    } catch (e) {
      error = e.toString();
    }

    if (!context.mounted) return;

    if (payload == null) {
      _toast(context, '导出失败：${error ?? '未知错误'}');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('备份字符串', style: AppTextStyles.titleMedium),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('已加密。复制后保存到笔记 / 云盘 / 电邮即可。',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryDim),
                ),
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: SelectableText(
                    payload!,
                    style: AppTextStyles.caption
                        .copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('关闭',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payload!));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _toast(context, '已复制到剪贴板');
              }
            },
            child: Text('复制',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final payloadCtl = TextEditingController();
    final passCtl = TextEditingController();

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          final canGo = payloadCtl.text.trim().isNotEmpty &&
              passCtl.text.length >= 4;
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('导入备份', style: AppTextStyles.titleMedium),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('粘贴之前导出的备份字符串，并输入对应口令。\n确认后会覆盖当前所有数据。',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: payloadCtl,
                    onChanged: (_) => setState(() {}),
                    minLines: 3,
                    maxLines: 6,
                    style: AppTextStyles.caption
                        .copyWith(fontFamily: 'monospace'),
                    cursorColor: AppColors.primary,
                    decoration: const InputDecoration(
                      hintText: 'IC1:...:...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtl,
                    onChanged: (_) => setState(() {}),
                    obscureText: true,
                    cursorColor: AppColors.primary,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(hintText: '加密口令'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('取消',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: canGo ? () => Navigator.pop(ctx, true) : null,
                child: Text('覆盖导入',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.danger)),
              ),
            ],
          );
        });
      },
    );

    if (go != true || !context.mounted) return;

    try {
      await BackupService().import(
        payload: payloadCtl.text,
        passphrase: passCtl.text,
      );
    } on BackupException catch (e) {
      if (context.mounted) _toast(context, e.message);
      return;
    } catch (e) {
      if (context.mounted) _toast(context, '导入失败：$e');
      return;
    }

    // 刷新所有依赖数据库的 provider
    ref.invalidate(coupleProfileProvider);
    ref.invalidate(cardCountsProvider);
    ref.invalidate(collectedCardIdsProvider);
    ref.invalidate(diaryCountProvider);
    ref.invalidate(diaryEntriesProvider);

    if (context.mounted) {
      _toast(context, '已恢复');
      context.go(Routes.home);
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await _confirmDialog(
      context,
      title: '确认重置？',
      body: '情侣信息、卡片记录、日记都将被清除。此操作不可撤销。',
      danger: true,
    );
    if (!context.mounted || !ok) return;
    await SecurityService().wipe();
    if (context.mounted) context.go(Routes.lock);
  }

  // ====================== 公共 UI 组件 ======================
  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.primary, letterSpacing: 3)),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool destructive = false,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon,
                    color: destructive
                        ? AppColors.danger
                        : disabled
                            ? AppColors.textDim
                            : AppColors.primary,
                    size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: destructive
                                  ? AppColors.danger
                                  : AppColors.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: disabled
                        ? AppColors.textDim
                        : AppColors.textSecondary,
                    size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<bool> _confirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    bool danger = false,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(body, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(danger ? '确定' : '继续',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: danger ? AppColors.danger : AppColors.primary)),
          ),
        ],
      ),
    );
    return r == true;
  }
}

// ====================== 子部件：编辑情侣信息 ======================
class _EditCoupleSheet extends StatefulWidget {
  final CoupleProfile profile;
  const _EditCoupleSheet({required this.profile});

  @override
  State<_EditCoupleSheet> createState() => _EditCoupleSheetState();
}

class _EditCoupleSheetState extends State<_EditCoupleSheet> {
  late final TextEditingController _myNameCtl;
  late final TextEditingController _partnerNameCtl;
  late String _myAvatarId;
  late String _partnerAvatarId;
  late DateTime _anniversary;

  @override
  void initState() {
    super.initState();
    _myNameCtl = TextEditingController(text: widget.profile.myName);
    _partnerNameCtl = TextEditingController(text: widget.profile.partnerName);
    _myAvatarId = widget.profile.myAvatar;
    _partnerAvatarId = widget.profile.partnerAvatar;
    _anniversary = widget.profile.anniversary;
  }

  @override
  void dispose() {
    _myNameCtl.dispose();
    _partnerNameCtl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _myNameCtl.text.trim().isNotEmpty &&
      _partnerNameCtl.text.trim().isNotEmpty &&
      _myAvatarId != _partnerAvatarId;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('编辑情侣信息', style: AppTextStyles.titleMedium),
            const SizedBox(height: 20),
            Text('你的昵称', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            _nameField(_myNameCtl),
            const SizedBox(height: 12),
            Text('你的头像', style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            _avatarRow(
              selected: _myAvatarId,
              onPick: (id) {
                if (id == _partnerAvatarId) return;
                setState(() => _myAvatarId = id);
              },
            ),
            const SizedBox(height: 24),
            Text('TA 的昵称', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            _nameField(_partnerNameCtl),
            const SizedBox(height: 12),
            Text('TA 的头像', style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            _avatarRow(
              selected: _partnerAvatarId,
              onPick: (id) {
                if (id == _myAvatarId) return;
                setState(() => _partnerAvatarId = id);
              },
            ),
            if (_myAvatarId == _partnerAvatarId)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('两人头像不能相同',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.danger)),
              ),
            const SizedBox(height: 24),
            Text('纪念日', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryDim),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      '${_anniversary.year} 年 ${_anniversary.month} 月 ${_anniversary.day} 日',
                      style: AppTextStyles.bodyLarge,
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            GoldButton(
              label: '保存',
              width: double.infinity,
              onPressed: _canSave
                  ? () {
                      Navigator.pop(
                        context,
                        widget.profile.copyWith(
                          myName: _myNameCtl.text.trim(),
                          partnerName: _partnerNameCtl.text.trim(),
                          myAvatar: _myAvatarId,
                          partnerAvatar: _partnerAvatarId,
                          anniversary: _anniversary,
                        ),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
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
          dialogTheme: const DialogTheme(backgroundColor: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _anniversary = picked);
  }

  Widget _nameField(TextEditingController c) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      maxLength: 8,
      style: AppTextStyles.bodyLarge,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: '昵称',
        filled: true,
        fillColor: AppColors.bg,
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

  Widget _avatarRow({
    required String selected,
    required ValueChanged<String> onPick,
  }) {
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
}

// ====================== 子部件：PIN 修改 / 验证 ======================
class _PinChangeDialog extends StatefulWidget {
  final String title;
  final int digits;
  final bool requireOld;
  final Future<bool> Function(String pin) verifyOld;
  final Future<bool> Function(String pin) onConfirm;

  const _PinChangeDialog({
    required this.title,
    required this.digits,
    required this.requireOld,
    required this.verifyOld,
    required this.onConfirm,
  });

  @override
  State<_PinChangeDialog> createState() => _PinChangeDialogState();
}

class _PinChangeDialogState extends State<_PinChangeDialog> {
  final _oldCtl = TextEditingController();
  final _newCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _oldCtl.dispose();
    _newCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final newOk = _newCtl.text.length == widget.digits;
    final confirmOk = _confirmCtl.text == _newCtl.text;
    final oldOk = !widget.requireOld || _oldCtl.text.length == widget.digits;
    return newOk && confirmOk && oldOk && !_busy;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    if (widget.requireOld) {
      final ok = await widget.verifyOld(_oldCtl.text);
      if (!ok) {
        setState(() {
          _busy = false;
          _error = '原密码不正确';
          _oldCtl.clear();
        });
        return;
      }
    }
    final ok = await widget.onConfirm(_newCtl.text);
    if (!mounted) return;
    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.title, style: AppTextStyles.titleMedium),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.requireOld) ...[
              _PinField(
                label: '当前密码',
                controller: _oldCtl,
                length: widget.digits,
                onChanged: () => setState(() => _error = null),
                autofocus: true,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_error!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.danger)),
                ),
              const SizedBox(height: 14),
            ],
            _PinField(
              label: '新密码（${widget.digits} 位数字）',
              controller: _newCtl,
              length: widget.digits,
              autofocus: !widget.requireOld,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 14),
            _PinField(
              label: '再次输入新密码',
              controller: _confirmCtl,
              length: widget.digits,
              onChanged: () => setState(() {}),
            ),
            if (_confirmCtl.text.isNotEmpty && _confirmCtl.text != _newCtl.text)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('两次输入不一致',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.danger)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text('取消',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text('保存',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _PinVerifyDialog extends StatefulWidget {
  final String title;
  final int digits;
  final Future<bool> Function(String pin) verify;

  const _PinVerifyDialog({
    required this.title,
    required this.digits,
    required this.verify,
  });

  @override
  State<_PinVerifyDialog> createState() => _PinVerifyDialogState();
}

class _PinVerifyDialogState extends State<_PinVerifyDialog> {
  final _ctl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ok = await widget.verify(_ctl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = '密码不正确';
        _ctl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGo = _ctl.text.length == widget.digits && !_busy;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.title, style: AppTextStyles.titleMedium),
      content: _PinField(
        label: '${widget.digits} 位密码',
        controller: _ctl,
        length: widget.digits,
        autofocus: true,
        onChanged: () => setState(() => _error = null),
        errorText: _error,
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text('取消',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: canGo ? _submit : null,
          child: Text('确认',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _PinField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int length;
  final VoidCallback onChanged;
  final bool autofocus;
  final String? errorText;

  const _PinField({
    required this.label,
    required this.controller,
    required this.length,
    required this.onChanged,
    this.autofocus = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      keyboardType: TextInputType.number,
      maxLength: length,
      obscureText: true,
      autofocus: autofocus,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.bodyLarge.copyWith(letterSpacing: 6),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        errorText: errorText,
      ),
    );
  }
}
