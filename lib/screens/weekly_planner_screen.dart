import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';

class WeeklyPlannerScreen extends StatelessWidget {
  const WeeklyPlannerScreen({super.key});

  static const dayLabels = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final dateRangeStr = '${DateFormat('d').format(startOfWeek)} - ${DateFormat('d MMMM yyyy', 'ar').format(endOfWeek)}';

    return AppScaffold(
      title: 'المخطط الأسبوعي',
      showNav: false,
      body: StreamBuilder<List<Task>>(
        stream: db.tasksDao.watchAll(),
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dateRangeStr, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(7, (index) {
                final dayDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: index));
                final dayTasks = allTasks.where((t) => 
                  t.date.year == dayDate.year && 
                  t.date.month == dayDate.month && 
                  t.date.day == dayDate.day &&
                  !t.isDeleted
                ).toList();
                
                final dayName = dayLabels[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 70, child: Text(dayName, style: Theme.of(context).textTheme.titleSmall)),
                        Expanded(
                          child: dayTasks.isEmpty
                              ? Text('لا توجد مهام', style: Theme.of(context).textTheme.bodySmall)
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: dayTasks
                                      .map((t) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(t.priority).withOpacity(0.15), 
                                              borderRadius: BorderRadius.circular(10)
                                            ),
                                            child: Text(
                                              t.title, 
                                              style: TextStyle(
                                                color: _getPriorityColor(t.priority), 
                                                fontSize: 12, 
                                                fontWeight: FontWeight.w600
                                              )
                                            ),
                                          ))
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        }
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }
}
