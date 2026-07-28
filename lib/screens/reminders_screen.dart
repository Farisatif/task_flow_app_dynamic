import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    return AppScaffold(
      title: 'التذكيرات',
      showNav: false,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showAddDialog(context, db),
        child: const Icon(Icons.add_alert_outlined, color: Colors.white),
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: db.remindersDao.watchAll(),
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final r = reminders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey('reminder-${r.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  onDismissed: (_) => db.remindersDao.deleteReminder(r.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      value: r.isActive,
                      activeColor: AppColors.primary,
                      onChanged: (v) => db.remindersDao.setActive(r.id, v),
                      title: Text(r.title, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(r.timeLabel, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('لا توجد تذكيرات نشطة', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('سوف تظهر التذكيرات المجدولة هنا', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, AppDatabase db) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تذكير جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'العنوان')),
            const SizedBox(height: 12),
            TextField(controller: timeController, decoration: const InputDecoration(labelText: 'التوقيت (مثال: 09:00 - اليوم)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              await db.remindersDao.insertReminder(RemindersCompanion.insert(
                title: titleController.text.trim(),
                timeLabel: timeController.text.trim().isEmpty ? 'بدون توقيت' : timeController.text.trim(),
              ));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
