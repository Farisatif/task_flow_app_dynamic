import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/utils/notification_service.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

enum _ReminderFilter { all, active, inactive }

extension on _ReminderFilter {
  String get label {
    switch (this) {
      case _ReminderFilter.all:
        return 'الكل';
      case _ReminderFilter.active:
        return 'النشطة';
      case _ReminderFilter.inactive:
        return 'المعطلة';
    }
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ReminderFilter _filter = _ReminderFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Reminder> _applyFilters(List<Reminder> reminders) {
    final query = _searchController.text.trim().toLowerCase();

    return reminders.where((reminder) {
      final matchesQuery = query.isEmpty ||
          reminder.title.toLowerCase().contains(query) ||
          reminder.timeLabel.toLowerCase().contains(query);

      final matchesFilter = switch (_filter) {
        _ReminderFilter.all => true,
        _ReminderFilter.active => reminder.isActive,
        _ReminderFilter.inactive => !reminder.isActive,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'التذكيرات',
      showNav: false,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () => _showAddBottomSheet(context, db),
        icon: const Icon(Icons.add_alert_outlined, color: Colors.white),
        label: const Text(
          'تذكير جديد',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: db.remindersDao.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل التذكيرات',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final reminders = snapshot.data ?? [];
          final filtered = _applyFilters(reminders);

          final totalCount = reminders.length;
          final activeCount = reminders.where((r) => r.isActive).length;
          final inactiveCount = totalCount - activeCount;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeaderCard(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  inactiveCount: inactiveCount,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'بحث في التذكيرات...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withOpacity(0.08),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _ReminderFilter.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _ReminderFilter.values[index];
                      final selected = item == _filter;

                      return ChoiceChip(
                        label: Text(item.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = item),
                        selectedColor: AppColors.primary.withOpacity(0.16),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : theme.dividerColor.withOpacity(0.10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: 'قائمة التذكيرات',
                  subtitle: 'اسحب للحذف أو عطّل التنبيه من داخل البطاقة',
                ),
                const SizedBox(height: 10),
                if (reminders.isEmpty)
                  _EmptyState(
                    title: 'لا توجد تذكيرات بعد',
                    subtitle: 'أضف أول تذكير ليظهر هنا',
                    onAdd: () => _showAddBottomSheet(context, db),
                  )
                else if (filtered.isEmpty)
                  _EmptyState(
                    title: 'لا توجد نتائج',
                    subtitle: 'جرّب تغيير كلمة البحث أو الفلتر',
                    onAdd: () => _showAddBottomSheet(context, db),
                  )
                else
                  ...filtered.map(
                    (reminder) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey('reminder-${reminder.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.priorityHigh.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.priorityHigh,
                          ),
                        ),
                        confirmDismiss: (_) => _confirmDelete(
                          context,
                          reminder.title,
                        ),
                        onDismissed: (_) {
                          NotificationService.cancelUserReminder(reminder.id);
                          db.remindersDao.deleteReminder(reminder.id);
                        },
                        child: _ReminderCard(
                          reminder: reminder,
                          onToggle: (value) async {
                            await db.remindersDao.setActive(reminder.id, value);
                            if (value) {
                              final scheduledTime = _parseNextReminderTime(
                                reminder.timeLabel,
                              );
                              if (scheduledTime != null) {
                                await NotificationService.scheduleUserReminder(
                                  reminderId: reminder.id,
                                  title: reminder.title,
                                  scheduledTime: scheduledTime,
                                );
                              }
                            } else {
                              await NotificationService.cancelUserReminder(
                                reminder.id,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف التذكير'),
        content: Text('هل تريد حذف "$title"؟'),
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
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  DateTime? _parseNextReminderTime(String label) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(label);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final isPm = label.contains('م');
    final isAm = label.contains('ص');
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _showAddBottomSheet(
    BuildContext context,
    AppDatabase db,
  ) async {
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '09:00 - اليوم');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.add_alert_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تذكير جديد',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'أنشئ تذكيرًا سريعًا ليظهر في قائمتك',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'العنوان',
                      hintText: 'مثال: شرب الماء',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'التوقيت',
                      hintText: 'مثال: 09:00 - اليوم',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ReminderPreview(
                    title: titleController.text.trim().isEmpty
                        ? 'معاينة التذكير'
                        : titleController.text.trim(),
                    timeLabel: timeController.text.trim().isEmpty
                        ? 'بدون توقيت'
                        : timeController.text.trim(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            final timeLabel = timeController.text.trim();

                            if (title.isEmpty) return;

                            final reminderId =
                                await db.remindersDao.insertReminder(
                              RemindersCompanion.insert(
                                title: title,
                                timeLabel:
                                    timeLabel.isEmpty ? 'بدون توقيت' : timeLabel,
                              ),
                            );

                            final scheduledTime =
                                _parseNextReminderTime(timeLabel);
                            if (scheduledTime != null) {
                              await NotificationService.scheduleUserReminder(
                                reminderId: reminderId,
                                title: title,
                                scheduledTime: scheduledTime,
                              );
                            }

                            if (!mounted) return;
                            Navigator.of(sheetContext).pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('إضافة'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    titleController.dispose();
    timeController.dispose();
  }
}

class _HeaderCard extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int inactiveCount;

  const _HeaderCard({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                child: Icon(Icons.notifications_active_rounded,
                    color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'مركز التذكيرات',
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
            'تابع تذكيراتك اليومية وفعّل ما تحتاجه بسرعة.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  label: 'الإجمالي',
                  value: '$totalCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  label: 'النشطة',
                  value: '$activeCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  label: 'المعطلة',
                  value: '$inactiveCount',
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
  final String label;
  final String value;

  const _HeroPill({
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
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
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

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final ValueChanged<bool> onToggle;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reminder.isActive
              ? AppColors.primary.withOpacity(0.12)
              : theme.dividerColor.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        value: reminder.isActive,
        activeColor: AppColors.primary,
        onChanged: onToggle,
        title: Text(
          reminder.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              reminder.timeLabel,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ReminderPreview extends StatelessWidget {
  final String title;
  final String timeLabel;

  const _ReminderPreview({
    required this.title,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(
          theme.brightness == Brightness.dark ? 0.12 : 0.08,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: theme.textTheme.bodySmall,
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
  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة تذكير'),
            ),
          ],
        ),
      ),
    );
  }
}
