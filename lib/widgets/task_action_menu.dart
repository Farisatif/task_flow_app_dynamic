import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';

class TaskActionMenu extends StatelessWidget {
  final Task task;

  const TaskActionMenu({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskActionMenu(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.bottom(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildItem(
            context,
            icon: Icons.edit_outlined,
            label: 'تعديل المهمة',
            onTap: () {
              Navigator.pop(context);
              context.push('/task-form/${task.id}');
            },
          ),
          _buildItem(
            context,
            icon: task.status == TaskStatus.completed ? Icons.undo : Icons.check_circle_outline,
            label: task.status == TaskStatus.completed ? 'إعادة تعيين كغير مكتملة' : 'تحديد كمكتملة',
            color: task.status == TaskStatus.completed ? null : AppColors.accentGreen,
            onTap: () {
              db.tasksDao.setStatus(task.id, task.status == TaskStatus.completed ? TaskStatus.pending : TaskStatus.completed);
              Navigator.pop(context);
            },
          ),
          _buildItem(
            context,
            icon: Icons.copy_outlined,
            label: 'تكرار المهمة',
            onTap: () async {
              await db.tasksDao.insertTask(TasksCompanion.insert(
                title: '${task.title} (نسخة)',
                date: task.date,
                startMinutes: task.startMinutes,
                endMinutes: task.endMinutes,
                priority: task.priority,
                status: const Value(TaskStatus.pending),
                categoryId: Value(task.categoryId),
                projectId: Value(task.projectId),
              ));
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const Divider(),
          _buildItem(
            context,
            icon: Icons.delete_outline,
            label: 'حذف المهمة',
            color: AppColors.priorityHigh,
            onTap: () {
              db.tasksDao.softDelete(task.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).iconTheme.color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
