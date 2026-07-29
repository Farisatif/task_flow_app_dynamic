import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/sound_service.dart';
import '../core/utils/time_utils.dart';

class QuickAddModal extends StatefulWidget {
  const QuickAddModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => const QuickAddModal(),
    );
  }

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final TextEditingController _titleController = TextEditingController();

  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  TaskPriority _priority = TaskPriority.medium;
  int? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateUtils.dateOnly(now);
    _startTime = TimeOfDay.fromDateTime(now);
    _endTime = _addHours(_startTime, 1);
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (mounted) setState(() {});
  }

  TimeOfDay _addHours(TimeOfDay time, int hours) {
    final total = time.hour * 60 + time.minute + (hours * 60);
    final normalized = total % (24 * 60);
    return TimeOfDay(
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }

  void _syncEndTimeIfNeeded() {
    final startMinutes = TimeUtils.toMinutes(_startTime);
    final endMinutes = TimeUtils.toMinutes(_endTime);

    if (endMinutes <= startMinutes) {
      _endTime = _addHours(_startTime, 1);
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    _syncEndTimeIfNeeded();
    setState(() => _saving = true);

    try {
      final db = context.read<AppDatabase>();

      await db.tasksDao.insertTask(
        TasksCompanion.insert(
          title: title,
          date: _date,
          startMinutes: TimeUtils.toMinutes(_startTime),
          endMinutes: TimeUtils.toMinutes(_endTime),
          priority: _priority,
          status: const Value(TaskStatus.pending),
          categoryId: Value(_categoryId),
          projectId: const Value.absent(),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      SoundService.playTaskCreate(context);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ المهمة، حاول مرة أخرى.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null && mounted) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _startTime = picked;
        _syncEndTimeIfNeeded();
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _endTime = picked;
        _syncEndTimeIfNeeded();
      });
    }
  }

  void _cyclePriority() {
    setState(() {
      _priority = TaskPriority.values[
          (_priority.index + 1) % TaskPriority.values.length];
    });
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'عالية';
      case TaskPriority.medium:
        return 'متوسطة';
      case TaskPriority.low:
        return 'منخفضة';
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.add_task_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة سريعة',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أنشئ مهمة جديدة بسرعة وبأقل عدد من الخطوات',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    hintText: 'ماذا تريد أن تنجز؟',
                    labelText: 'عنوان المهمة',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _PanelSection(
                  title: 'الوقت والتاريخ',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ActionChip(
                        icon: Icons.calendar_today_outlined,
                        label: intl.DateFormat('d MMM', 'ar').format(_date),
                        onTap: _pickDate,
                      ),
                      _ActionChip(
                        icon: Icons.access_time_rounded,
                        label: TimeUtils.formatMinutes(
                          TimeUtils.toMinutes(_startTime),
                        ),
                        onTap: _pickStartTime,
                      ),
                      _ActionChip(
                        icon: Icons.flag_outlined,
                        label: _priorityLabel(_priority),
                        color: _priorityColor(_priority),
                        onTap: _cyclePriority,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _PanelSection(
                  title: 'وقت الانتهاء',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ActionChip(
                        icon: Icons.schedule_rounded,
                        label: TimeUtils.formatMinutes(
                          TimeUtils.toMinutes(_endTime),
                        ),
                        onTap: _pickEndTime,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _endTime = _addHours(_startTime, 1);
                          });
                        },
                        icon: const Icon(Icons.restore_rounded),
                        label: const Text('ضبط تلقائي'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _CategoryPicker(
                  selectedId: _categoryId,
                  onSelected: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: 18),
                _PreviewCard(
                  title: _titleController.text.trim().isEmpty
                      ? 'معاينة المهمة'
                      : _titleController.text.trim(),
                  dateLabel:
                      intl.DateFormat('EEEE، d MMMM', 'ar').format(_date),
                  timeLabel:
                      '${TimeUtils.formatMinutes(TimeUtils.toMinutes(_startTime))} - ${TimeUtils.formatMinutes(TimeUtils.toMinutes(_endTime))}',
                  priorityLabel: _priorityLabel(_priority),
                  priorityColor: _priorityColor(_priority),
                  categoryId: _categoryId,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
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
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(_saving ? 'جاري الحفظ...' : 'إضافة المهمة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _PanelSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color?.withOpacity(0.28) ??
                  theme.dividerColor.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color ??
                    (isDark
                        ? theme.colorScheme.onSurface.withOpacity(0.75)
                        : theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color ??
                      (isDark
                          ? theme.colorScheme.onSurface.withOpacity(0.78)
                          : theme.colorScheme.onSurfaceVariant),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const _CategoryPicker({
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return StreamBuilder<List<Category>>(
      stream: db.categoriesDao.watchAll(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        Category? selected;

        if (selectedId != null) {
          for (final category in categories) {
            if (category.id == selectedId) {
              selected = category;
              break;
            }
          }
        }

        return _PanelSection(
          title: 'التصنيف',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionChip(
                icon: Icons.label_outline_rounded,
                label: selected?.name ?? 'بدون تصنيف',
                onTap: () => _openPicker(context, categories),
              ),
              if (selectedId != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: const Text('إزالة'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    List<Category> categories,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const SizedBox(height: 6),
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('بدون تصنيف'),
                onTap: () {
                  onSelected(null);
                  Navigator.of(sheetContext).pop();
                },
              ),
              const Divider(height: 1),
              ...categories.map(
                (category) => ListTile(
                  leading: Icon(
                    Icons.circle_rounded,
                    color: Color(category.color),
                    size: 18,
                  ),
                  title: Text(category.name),
                  onTap: () {
                    onSelected(category.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String timeLabel;
  final String priorityLabel;
  final Color priorityColor;
  final int? categoryId;

  const _PreviewCard({
    required this.title,
    required this.dateLabel,
    required this.timeLabel,
    required this.priorityLabel,
    required this.priorityColor,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(
          theme.brightness == Brightness.dark ? 0.12 : 0.08,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: priorityColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
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
                  '$dateLabel • $timeLabel',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'الأولوية: $priorityLabel${categoryId != null ? ' • يوجد تصنيف' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
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
