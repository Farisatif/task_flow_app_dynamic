import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/notification_service.dart';
import '../core/theme/theme_provider.dart';
import '../core/utils/settings_provider.dart';
import '../widgets/app_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'الإعدادات',
      showNav: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HeaderCard(
              primaryColor: settings.primaryColor,
              isDark: themeProvider.isDark,
              onProfileTap: () => context.push('/profile'),
            ),
            const SizedBox(height: 16),
            _SectionTitle(
              title: 'التجربة والواجهة',
              subtitle: 'تخصيص شكل التطبيق وطريقة ظهوره',
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'الملف الشخصي',
                  subtitle: 'تعديل الاسم والبريد والمستوى',
                  onTap: () => context.push('/profile'),
                ),
                const _Divider(),
                _SwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'الوضع الليلي',
                  subtitle: 'تبديل السمة الداكنة أو الفاتحة',
                  value: themeProvider.isDark,
                  onChanged: (v) => themeProvider.setDark(v),
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.palette_outlined,
                  title: 'لون التطبيق',
                  subtitle: 'تخصيص اللون الأساسي',
                  trailing: CircleAvatar(
                    radius: 12,
                    backgroundColor: settings.primaryColor,
                  ),
                  onTap: () => _showColorSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'الأصوات والتنبيهات',
              subtitle: 'الاهتزاز والصوت والإشعارات',
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SwitchTile(
                  icon: Icons.volume_up_outlined,
                  title: 'أصوات التطبيق',
                  subtitle: 'تشغيل أصوات التفاعل',
                  value: settings.soundEnabled,
                  onChanged: (v) => settings.setSoundEnabled(v),
                ),
                const _Divider(),
                _SwitchTile(
                  icon: Icons.vibration_outlined,
                  title: 'الاهتزاز',
                  subtitle: 'الاستجابة اللمسية عند التفاعل',
                  value: settings.hapticEnabled,
                  onChanged: (v) => settings.setHapticEnabled(v),
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.notifications_outlined,
                  title: 'إعدادات التذكيرات',
                  subtitle: 'إدارة الإشعارات والتنبيهات',
                  onTap: () => context.push('/reminders'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'البيانات والأمان',
              subtitle: 'النسخ الاحتياطي والخصوصية',
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.backup_outlined,
                  title: 'النسخ الاحتياطي والمزامنة',
                  subtitle: 'حفظ بياناتك واسترجاعها',
                  onTap: () => context.push('/backup-sync'),
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'الخصوصية والأمان',
                  subtitle: 'التحكم في الأمان والخصوصية',
                  onTap: () => _showPrivacyInfo(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'عن التطبيق',
              subtitle: 'المساعدة والمعلومات العامة',
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.help_outline_rounded,
                  title: 'مساعدة ودعم',
                  subtitle: 'أسئلة شائعة ومركز الدعم',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('صفحة المساعدة لم تُربط بعد.'),
                      ),
                    );
                  },
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.info_outline_rounded,
                  title: 'عن Task Flow',
                  subtitle: 'الإصدار 1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Task Flow',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'مسح جميع البيانات',
                  subtitle: 'حذف بيانات التطبيق من الجهاز',
                  iconColor: AppColors.priorityHigh,
                  titleColor: AppColors.priorityHigh,
                  onTap: () => _confirmClearData(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPrivacyInfo(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الخصوصية والأمان'),
        content: const Text(
          'تُخزّن مهامك وبياناتك محليًا على هذا الجهاز عبر قاعدة SQLite. لا تتم مشاركة البيانات مع خدمة خارجية من داخل التطبيق الحالي. استخدم النسخ الاحتياطي بعد ربطه بآلية تصدير فعلية قبل حذف التطبيق أو تغيير الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  Future<void> _showColorSheet(BuildContext context) async {
    final colors = <Color>[
      AppColors.primary,
      AppColors.accentBlue,
      AppColors.accentGreen,
      AppColors.accentOrange,
      AppColors.accentPink,
      AppColors.accentYellow,
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لون التطبيق',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اختر لونًا أساسيًا للتطبيق',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colors.map((color) {
                    return InkWell(
                      onTap: () {
                        context.read<SettingsProvider>().setPrimaryColor(color);
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تغيير لون التطبيق.')),
                        );
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('مسح جميع البيانات'),
        content: const Text(
          'هل تريد مسح جميع بيانات التطبيق؟ هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.priorityHigh,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (shouldClear != true || !context.mounted) return;

    final db = context.read<AppDatabase>();
    try {
      await NotificationService.cancelAll();
      await db.clearUserData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مسح جميع البيانات بنجاح.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر مسح البيانات: $error')),
      );
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onProfileTap;

  const _HeaderCard({
    required this.primaryColor,
    required this.isDark,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Icon(
                  isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإعدادات',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تحكم في مظهر التطبيق، التنبيهات، والبيانات',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _HeaderPill(
                      label: 'اللون',
                      value: 'مفعّل',
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    _HeaderPill(
                      label: 'الواجهة',
                      value: isDark ? 'داكنة' : 'فاتحة',
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.08));
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? AppColors.primary;
    final tc = titleColor ?? Theme.of(context).textTheme.bodyMedium?.color;

    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ic.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: ic, size: 22),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: tc,
            ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_left_rounded),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: Text(subtitle),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
