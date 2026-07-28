import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_provider.dart';
import '../core/utils/settings_provider.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();

    return AppScaffold(
      title: 'الإعدادات',
      showNav: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _group(context, 'التجربة والواجهة', [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('الملف الشخصي'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/profile'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('الوضع الليلي'),
              value: themeProvider.isDark,
              activeColor: AppColors.primary,
              onChanged: (v) => themeProvider.setDark(v),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('لون التطبيق'),
              trailing: CircleAvatar(radius: 12, backgroundColor: settings.primaryColor),
              onTap: () {
                // TODO: Implement color picker
              },
            ),
          ]),
          _group(context, 'الأصوات والتنبيهات', [
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: const Text('أصوات التطبيق'),
              value: settings.soundEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => settings.setSoundEnabled(v),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration_outlined),
              title: const Text('الاهتزاز (Haptics)'),
              value: settings.hapticEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => settings.setHapticEnabled(v),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('إعدادات الإشعارات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/reminders'),
            ),
          ]),
          _group(context, 'البيانات والأمان', [
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('النسخ الاحتياطي والمزامنة'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/backup-sync'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('الخصوصية والأمان'),
              trailing: const Icon(Icons.chevron_left),
            ),
          ]),
          _group(context, 'عن التطبيق', [
            ListTile(leading: const Icon(Icons.help_outline), title: const Text('مساعدة ودعم'), trailing: const Icon(Icons.chevron_left)),
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('عن Task Flow'), subtitle: const Text('الإصدار 1.0.0')),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.priorityHigh),
              title: const Text('مسح جميع البيانات', style: TextStyle(color: AppColors.priorityHigh)),
              onTap: () {
                // TODO: Implement data clear
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(child: Column(children: children)),
        ],
      ),
    );
  }
}
