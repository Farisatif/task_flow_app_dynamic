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
        onPressed: () => _showAddDialog(context, db),
        child: const Icon(Icons.add_alert_outlined, color: Colors.white),
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: db.remindersDao.watchAll(),
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return Center(child: Text('لا توجد تذكيرات بعد', style: Theme.of(context).textTheme.bodyMedium));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: reminders
                .map((r) => Dismissible(
                      key: ValueKey('reminder-${r.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(color: AppColors.priorityHigh.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.delete_outline, color: AppColors.priorityHigh),
                      ),
                      onDismissed: (_) => db.remindersDao.deleteReminder(r.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: SwitchListTile(
                          value: r.isActive,
                          activeColor: AppColors.primary,
                          onChanged: (v) => db.remindersDao.setActive(r.id, v),
                          title: Text(r.title, style: Theme.of(context).textTheme.titleSmall),
                          subtitle: Text(r.timeLabel, style: Theme.of(context).textTheme.bodySmall),
                          secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
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
