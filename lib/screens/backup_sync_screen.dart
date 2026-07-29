import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  bool autoSync = true;
  bool wifiOnly = true;
  bool includeAttachments = true;

  DateTime? lastBackup = DateTime(2024, 5, 19, 10, 30);
  double backupSizeMb = 45.2;
  int backupsCount = 6;
  int syncSuccessRate = 94;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBackup = lastBackup != null;

    return AppScaffold(
      title: 'النسخ الاحتياطي والمزامنة',
      showNav: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(
            lastBackup: hasBackup ? _formatDateTime(lastBackup!) : 'لا توجد نسخة حتى الآن',
            backupSize: _formatSize(backupSizeMb),
            syncRate: syncSuccessRate,
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _MetricCard(
                title: 'عدد النسخ',
                value: '$backupsCount',
                icon: Icons.backup_rounded,
                color: AppColors.primary,
              ),
              _MetricCard(
                title: 'حجم البيانات',
                value: _formatSize(backupSizeMb),
                icon: Icons.storage_rounded,
                color: AppColors.accentBlue,
              ),
              _MetricCard(
                title: 'نسبة النجاح',
                value: '$syncSuccessRate%',
                icon: Icons.check_circle_rounded,
                color: AppColors.accentGreen,
              ),
              _MetricCard(
                title: 'الحالة',
                value: autoSync ? 'نشطة' : 'متوقفة',
                icon: autoSync ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                color: autoSync ? AppColors.accentGreen : AppColors.priorityHigh,
              ),
            ],
          ),

          const SizedBox(height: 18),
          _SectionTitle(
            title: 'الإعدادات الذكية',
            subtitle: 'تحكم بسلوك النسخ الاحتياطي والمزامنة',
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: autoSync,
                  onChanged: (value) {
                    setState(() => autoSync = value);
                    _showMessage(
                      context,
                      value ? 'تم تفعيل المزامنة التلقائية' : 'تم إيقاف المزامنة التلقائية',
                    );
                  },
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.sync_rounded),
                  title: const Text(
                    'مزامنة تلقائية',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('تحديث البيانات بشكل تلقائي عند التغيير'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: wifiOnly,
                  onChanged: (value) {
                    setState(() => wifiOnly = value);
                    _showMessage(
                      context,
                      value ? 'سيتم النسخ عبر Wi-Fi فقط' : 'يمكن النسخ عبر أي اتصال',
                    );
                  },
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.wifi_rounded),
                  title: const Text(
                    'Wi-Fi فقط',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('منع النسخ الاحتياطي عبر بيانات الهاتف'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: includeAttachments,
                  onChanged: (value) {
                    setState(() => includeAttachments = value);
                    _showMessage(
                      context,
                      value ? 'سيتم تضمين المرفقات' : 'سيتم تجاهل المرفقات',
                    );
                  },
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.attach_file_rounded),
                  title: const Text(
                    'تضمين المرفقات',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('إضافة الملفات والصور داخل النسخة الاحتياطية'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          _SectionTitle(
            title: 'الإجراءات',
            subtitle: 'أدوات سريعة لإدارة النسخ الاحتياطية',
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _runBackup(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('نسخ احتياطي الآن'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _restoreBackup(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('استعادة'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          _SectionTitle(
            title: 'النسخ السابقة',
            subtitle: 'آخر النسخ الاحتياطية المسجلة',
          ),
          const SizedBox(height: 10),

          if (hasBackup)
            ..._buildBackupHistory(context)
          else
            _EmptyState(
              onCreate: () => _runBackup(context),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildBackupHistory(BuildContext context) {
    final backups = <_BackupItem>[
      _BackupItem(
        date: DateTime(2024, 5, 19, 10, 30),
        size: '45.2 MB',
        status: 'ناجحة',
        statusColor: AppColors.accentGreen,
      ),
      _BackupItem(
        date: DateTime(2024, 5, 16, 22, 10),
        size: '44.8 MB',
        status: 'ناجحة',
        statusColor: AppColors.accentGreen,
      ),
      _BackupItem(
        date: DateTime(2024, 5, 12, 9, 15),
        size: '43.9 MB',
        status: 'ناجحة',
        statusColor: AppColors.accentGreen,
      ),
    ];

    return backups
        .map(
          (backup) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: backup.statusColor.withOpacity(0.14),
                child: Icon(
                  Icons.cloud_done_rounded,
                  color: backup.statusColor,
                ),
              ),
              title: Text(
                _formatDateTime(backup.date),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('الحجم: ${backup.size}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: backup.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  backup.status,
                  style: TextStyle(
                    color: backup.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Future<void> _runBackup(BuildContext context) async {
    _showMessage(context, 'تم بدء النسخ الاحتياطي...');
    await Future<void>.delayed(const Duration(milliseconds: 700));

    setState(() {
      lastBackup = DateTime.now();
      backupsCount += 1;
      backupSizeMb += 0.6;
      syncSuccessRate = (syncSuccessRate + 1).clamp(0, 100);
    });

    if (mounted) {
      _showMessage(context, 'اكتمل النسخ الاحتياطي بنجاح');
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'استعادة نسخة سابقة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'اختر النسخة التي تريد استعادتها. هذه الصفحة حالياً تعرض واجهة جاهزة للتوصيل مع المنطق الفعلي لاحقًا.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...[
                '19 مايو 2024 - 10:30',
                '16 مايو 2024 - 22:10',
                '12 مايو 2024 - 09:15',
              ].map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restore_rounded),
                  title: Text(item),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showMessage(context, 'تم اختيار نسخة: $item');
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month $year، $hour:$minute';
  }

  static String _formatSize(double mb) {
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class _BackupItem {
  final DateTime date;
  final String size;
  final String status;
  final Color statusColor;

  _BackupItem({
    required this.date,
    required this.size,
    required this.status,
    required this.statusColor,
  });
}

class _HeroCard extends StatelessWidget {
  final String lastBackup;
  final String backupSize;
  final int syncRate;

  const _HeroCard({
    required this.lastBackup,
    required this.backupSize,
    required this.syncRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.cloud_done_outlined, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'نسخ احتياطي آمن ومرن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'حافظ على بياناتك مع مزامنة ذكية، واستعادة منظمة، ومتابعة دقيقة للحالة.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  icon: Icons.schedule_rounded,
                  label: 'آخر نسخة',
                  value: lastBackup,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.storage_rounded,
                  label: 'الحجم',
                  value: backupSize,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.insights_rounded,
                  label: 'النجاح',
                  value: '$syncRate%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.backup_outlined,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد نسخ سابقة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'ابدأ أول نسخة احتياطية لتأمين بياناتك.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('إنشاء نسخة الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
