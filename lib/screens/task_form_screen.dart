import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/notification_service.dart';
import '../core/utils/time_utils.dart';
import '../widgets/app_scaffold.dart';

/// شاشة إضافة/تعديل مهمة.
/// مرّر taskId للتعديل، أو اتركه null لإضافة مهمة جديدة.
class TaskFormScreen extends StatefulWidget {
  final int? taskId;

  const TaskFormScreen({super.key, this.taskId});

  bool get isEditing => taskId != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  TaskPriority _priority = TaskPriority.medium;
  int? _categoryId;
  int? _projectId;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _notesController.addListener(_onTextChanged);
    _loadIfEditing();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _notesController.removeListener(_onTextChanged);
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadIfEditing() async {
    if (widget.isEditing) {
      final db = context.read<AppDatabase>();
      final task = await db.tasksDao.watchById(widget.taskId!).first;

      if (task != null) {
        _titleController.text = task.title;
        _notesController.text = task.notes ?? '';
        _date = task.date;
        _start = TimeUtils.fromMinutes(task.startMinutes);
        _end = TimeUtils.fromMinutes(task.endMinutes);
        _priority = task.priority;
        _categoryId = task.categoryId;
        _projectId = task.projectId;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _start = picked;
          _ensureValidEndTime();
        } else {
          _end = picked;
          _ensureValidEndTime();
        }
      });
    }
  }

  void _ensureValidEndTime() {
    final startMin = TimeUtils.toMinutes(_start);
    final endMin = TimeUtils.toMinutes(_end);

    if (endMin <= startMin) {
      _end = TimeOfDay(
        hour: (_start.hour + 1) % 24,
        minute: _start.minute,
      );
    }
  }

  DateTime _taskReminderTime() {
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      _start.hour,
      _start.minute,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final db = context.read<AppDatabase>();
    final dayOnly = DateTime(_date.year, _date.month, _date.day);
    final startMin = TimeUtils.toMinutes(_start);
    var endMin = TimeUtils.toMinutes(_end);

    if (endMin <= startMin) {
      endMin = startMin + 30;
    }

    setState(() => _saving = true);

    try {
      final reminderTime = _taskReminderTime();
      final reminderBody = 'من ${_formatTime(_start)} إلى ${_formatTime(_end)}';

      if (widget.isEditing) {
        final existing = await db.tasksDao.watchById(widget.taskId!).first;

        if (existing != null) {
          await db.tasksDao.updateTask(
            existing.copyWith(
              title: _titleController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              date: dayOnly,
              startMinutes: startMin,
              endMinutes: endMin,
              priority: _priority,
              categoryId: Value(_categoryId),
              projectId: Value(_projectId),
              updatedAt: DateTime.now(),
            ),
          );

          await NotificationService.cancelReminder(widget.taskId!);
          await NotificationService.scheduleTaskReminder(
            taskId: widget.taskId!,
            title: _titleController.text.trim(),
            scheduledTime: reminderTime,
            body: reminderBody,
          );
        }
      } else {
        final insertedId = await db.tasksDao.insertTask(
          TasksCompanion.insert(
            title: _titleController.text.trim(),
            notes: Value(
              _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
            date: dayOnly,
            startMinutes: startMin,
            endMinutes: endMin,
            priority: _priority,
            status: const Value(TaskStatus.pending),
            categoryId: Value(_categoryId),
            projectId: Value(_projectId),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );

        await NotificationService.scheduleTaskReminder(
          taskId: insertedId,
          title: _titleController.text.trim(),
          scheduledTime: reminderTime,
          body: reminderBody,
        );
      }

      if (!mounted) return;
      context.pop();
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف المهمة'),
        content: const Text(
          'هل أنت متأكد من حذف هذه المهمة؟ لا يمكن التراجع عن هذا الإجراء.',
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
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.taskId != null) {
      await NotificationService.cancelReminder(widget.taskId!);
      await context.read<AppDatabase>().tasksDao.softDelete(widget.taskId!);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);
    final isEditing = widget.isEditing;

    return AppScaffold(
      title: isEditing ? 'تعديل المهمة' : 'مهمة جديدة',
      showNav: false,
      actions: isEditing
          ? [
              IconButton(
                tooltip: 'حذف المهمة',
                onPressed: _delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.priorityHigh,
                ),
              ),
            ]
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _HeaderCard(
                    isEditing: isEditing,
                    title: _titleController.text.trim().isEmpty
                        ? (isEditing ? 'تعديل مهمة' : 'أنشئ مهمة جديدة')
                        : _titleController.text.trim(),
                    dateLabel: _formatDate(_date),
                    timeLabel: '${_formatTime(_start)} - ${_formatTime(_end)}',
                    priority: _priority,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'المعلومات الأساسية',
                    subtitle: 'عنوان المهمة والتفاصيل المساعدة',
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'عنوان المهمة',
                          hintText: 'مثال: مراجعة واجهة التطبيق',
                          prefixIcon: const Icon(Icons.task_alt_rounded),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.35),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'الرجاء إدخال عنوان'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                          hintText: 'أي تفاصيل إضافية تساعدك لاحقًا',
                          prefixIcon: const Icon(Icons.notes_rounded),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.35),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'الوقت والتاريخ',
                    subtitle: 'اختر اليوم والساعة المناسبة',
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _PickTile(
                              icon: Icons.calendar_today_rounded,
                              title: 'التاريخ',
                              value: _formatDate(_date),
                              onTap: _pickDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PickTile(
                              icon: Icons.access_time_rounded,
                              title: 'من',
                              value: _formatTime(_start),
                              onTap: () => _pickTime(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PickTile(
                              icon: Icons.access_time_filled_rounded,
                              title: 'إلى',
                              value: _formatTime(_end),
                              onTap: () => _pickTime(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'الأولوية',
                    subtitle: 'حدد درجة أهمية المهمة',
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    children: [
                      SegmentedButton<TaskPriority>(
                        segments: const [
                          ButtonSegment(
                            value: TaskPriority.high,
                            label: Text('عالية'),
                            icon: Icon(Icons.priority_high_rounded),
                          ),
                          ButtonSegment(
                            value: TaskPriority.medium,
                            label: Text('متوسطة'),
                            icon: Icon(Icons.drag_handle_rounded),
                          ),
                          ButtonSegment(
                            value: TaskPriority.low,
                            label: Text('منخفضة'),
                            icon: Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                        ],
                        selected: {_priority},
                        onSelectionChanged: (s) =>
                            setState(() => _priority = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'الترتيب',
                    subtitle: 'ربط المهمة بتصنيف أو مشروع',
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    children: [
                      StreamBuilder<List<Category>>(
                        stream: db.categoriesDao.watchAll(),
                        builder: (context, snapshot) {
                          final categories = snapshot.data ?? [];
                          final selectedExists = categories.any(
                            (c) => c.id == _categoryId,
                          );

                          return DropdownButtonFormField<int?>(
                            value: selectedExists ? _categoryId : null,
                            decoration: InputDecoration(
                              labelText: 'التصنيف',
                              prefixIcon: const Icon(Icons.label_outline_rounded),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('بدون تصنيف'),
                              ),
                              ...categories.map(
                                (c) => DropdownMenuItem<int?>(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _categoryId = v),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Project>>(
                        stream: db.projectsDao.watchAll(),
                        builder: (context, snapshot) {
                          final projects = snapshot.data ?? [];
                          final selectedExists = projects.any(
                            (p) => p.id == _projectId,
                          );

                          return DropdownButtonFormField<int?>(
                            value: selectedExists ? _projectId : null,
                            decoration: InputDecoration(
                              labelText: 'المشروع',
                              prefixIcon: const Icon(Icons.folder_outlined),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('بدون مشروع'),
                              ),
                              ...projects.map(
                                (p) => DropdownMenuItem<int?>(
                                  value: p.id,
                                  child: Text(p.name),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _projectId = v),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'معاينة سريعة',
                    subtitle: 'كيف ستبدو المهمة بعد الحفظ',
                  ),
                  const SizedBox(height: 10),
                  _PreviewCard(
                    title: _titleController.text.trim().isEmpty
                        ? 'عنوان المهمة'
                        : _titleController.text.trim(),
                    dateLabel: _formatDate(_date),
                    timeLabel: '${_formatTime(_start)} - ${_formatTime(_end)}',
                    priorityLabel: _priorityLabel(_priority),
                    priorityColor: _priorityColor(_priority),
                    notesLabel: _notesController.text.trim().isEmpty
                        ? 'لا توجد ملاحظات'
                        : _notesController.text.trim(),
                    hasCategory: _categoryId != null,
                    hasProject: _projectId != null,
                  ),
                  const SizedBox(height: 20),
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
                              : const Icon(Icons.check_rounded),
                          label: Text(_saving ? 'جاري الحفظ...' : 'حفظ المهمة'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  static String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'عالية';
      case TaskPriority.medium:
        return 'متوسطة';
      case TaskPriority.low:
        return 'منخفضة';
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isEditing;
  final String title;
  final String dateLabel;
  final String timeLabel;
  final TaskPriority priority;

  const _HeaderCard({
    required this.isEditing,
    required this.title,
    required this.dateLabel,
    required this.timeLabel,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _priorityColor(priority);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.edit_note_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEditing ? 'تعديل المهمة' : 'مهمة جديدة',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'التاريخ: $dateLabel  •  الوقت: $timeLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroPill(label: 'الأولوية', value: _priorityLabel(priority)),
              const SizedBox(width: 8),
              _HeroPill(label: 'اللون', value: 'نشط', color: color),
            ],
          ),
        ],
      ),
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'عالية';
      case TaskPriority.medium:
        return 'متوسطة';
      case TaskPriority.low:
        return 'منخفضة';
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _HeroPill({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = color ?? Colors.white;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pillColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
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

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({
    required this.children,
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
      child: Column(children: children),
    );
  }
}

class _PickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _PickTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String timeLabel;
  final String priorityLabel;
  final Color priorityColor;
  final String notesLabel;
  final bool hasCategory;
  final bool hasProject;

  const _PreviewCard({
    required this.title,
    required this.dateLabel,
    required this.timeLabel,
    required this.priorityLabel,
    required this.priorityColor,
    required this.notesLabel,
    required this.hasCategory,
    required this.hasProject,
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(16),
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
                  'الأولوية: $priorityLabel${hasCategory ? ' • تصنيف محدد' : ''}${hasProject ? ' • مشروع محدد' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notesLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
