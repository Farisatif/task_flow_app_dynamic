import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/local_backup_service.dart';
import '../core/utils/notification_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_state_view.dart';

/// إدارة لقطات SQLite المحلية. لا تدّعي هذه الشاشة وجود مزامنة سحابية.
class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  late final LocalBackupService _backupService;
  List<BackupSnapshot> _backups = const [];
  bool _isLoading = true;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _backupService = LocalBackupService(context.read<AppDatabase>());
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final backups = await _backupService.listBackups();
      if (mounted) setState(() => _backups = backups);
    } catch (error) {
      if (mounted) _showMessage('تعذر قراءة النسخ الاحتياطية: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final snapshot = await _backupService.createBackup();
      await _loadBackups();
      if (mounted) {
        _showMessage('تم إنشاء نسخة محلية بحجم ${_formatSize(snapshot.sizeBytes)}.');
      }
    } catch (error) {
      if (mounted) _showMessage('تعذر إنشاء النسخة الاحتياطية: $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _restoreBackup(BackupSnapshot snapshot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة النسخة؟'),
        content: Text(
          'سيجري استبدال بيانات Task Flow الحالية بمحتوى نسخة ${_formatDate(snapshot.createdAt)}. '
          'لن يمكن التراجع عن البيانات الجديدة بعد الاستعادة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.priorityHigh),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isWorking = true);
    try {
      await _backupService.restoreBackup(snapshot);
      await NotificationService.cancelAll();
      await NotificationService.rescheduleTasks(context.read<AppDatabase>());
      if (mounted) _showMessage('اكتملت استعادة البيانات من النسخة المحلية.');
    } catch (error) {
      if (mounted) _showMessage('تعذرت الاستعادة: $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _deleteBackup(BackupSnapshot snapshot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف النسخة؟'),
        content: Text('سيُحذف الملف ${snapshot.fileName} من هذا الجهاز فقط.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.priorityHigh),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isWorking = true);
    try {
      await _backupService.deleteBackup(snapshot);
      await _loadBackups();
      if (mounted) _showMessage('حُذفت النسخة المحلية.');
    } catch (error) {
      if (mounted) _showMessage('تعذر حذف النسخة: $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'النسخ الاحتياطي المحلي',
      showNav: false,
      body: _isLoading
          ? const AppLoadingState(label: 'جارٍ قراءة النسخ المحلية…')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeroCard(
                  backupsCount: _backups.length,
                  latestBackup:
                      _backups.isEmpty ? null : _backups.first.createdAt,
                ),
                const SizedBox(height: 16),
                _LocalOnlyNotice(theme: theme),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _isWorking ? null : _createBackup,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _isWorking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt_rounded),
                  label: Text(_isWorking ? 'جارٍ التنفيذ…' : 'إنشاء نسخة محلية الآن'),
                ),
                const SizedBox(height: 20),
                Text(
                  'النسخ المتاحة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تُرتّب النسخ من الأحدث إلى الأقدم.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (_backups.isEmpty)
                  AppEmptyState(
                    icon: Icons.backup_outlined,
                    title: 'لا توجد نسخة محلية بعد',
                    message:
                        'أنشئ لقطة لبياناتك الحالية قبل أي تغيير مهم داخل التطبيق.',
                    actionLabel: 'إنشاء نسخة',
                    onAction: _isWorking ? null : _createBackup,
                  )
                else
                  ..._backups.map(
                    (snapshot) => _BackupTile(
                      snapshot: snapshot,
                      enabled: !_isWorking,
                      onRestore: () => _restoreBackup(snapshot),
                      onDelete: () => _deleteBackup(snapshot),
                    ),
                  ),
              ],
            ),
    );
  }

  String _formatDate(DateTime value) =>
      intl.DateFormat('d MMMM yyyy، h:mm a', 'ar').format(value);

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _HeroCard extends StatelessWidget {
  final int backupsCount;
  final DateTime? latestBackup;

  const _HeroCard({required this.backupsCount, required this.latestBackup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = latestBackup == null
        ? 'لا توجد نسخة بعد'
        : intl.DateFormat('d MMMM، h:mm a', 'ar').format(latestBackup!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.shield_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بياناتك محفوظة على جهازك',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'آخر نسخة: $latest',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$backupsCount ${backupsCount == 1 ? 'نسخة متاحة' : 'نسخ متاحة'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

class _LocalOnlyNotice extends StatelessWidget {
  final ThemeData theme;

  const _LocalOnlyNotice({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.accentBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'هذه اللقطات محفوظة محليًا داخل Task Flow وليست مزامنة سحابية. '
              'تحتفظ بنسخة من قاعدة البيانات، ولا تنقل الملفات المرفقة خارج مساحة التطبيق.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  final BackupSnapshot snapshot;
  final bool enabled;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupTile({
    required this.snapshot,
    required this.enabled,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = intl.DateFormat('d MMMM yyyy، h:mm a', 'ar')
        .format(snapshot.createdAt);
    final size = snapshot.sizeBytes < 1024 * 1024
        ? '${(snapshot.sizeBytes / 1024).toStringAsFixed(1)} KB'
        : '${(snapshot.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.accentGreen.withOpacity(0.14),
          child: const Icon(Icons.backup_rounded, color: AppColors.accentGreen),
        ),
        title: Text(
          date,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text('الحجم: $size'),
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: 'استعادة هذه النسخة',
              onPressed: enabled ? onRestore : null,
              icon: const Icon(Icons.restore_rounded),
            ),
            IconButton(
              tooltip: 'حذف النسخة',
              onPressed: enabled ? onDelete : null,
              color: AppColors.priorityHigh,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
