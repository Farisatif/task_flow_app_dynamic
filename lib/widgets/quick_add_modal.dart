import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/time_utils.dart';
import '../core/utils/sound_service.dart';

class QuickAddModal extends StatefulWidget {
  const QuickAddModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddModal(),
    );
  }

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final _titleController = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
  TaskPriority _priority = TaskPriority.medium;
  int? _categoryId;
  int? _projectId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    final db = context.read<AppDatabase>();
    SoundService.playTaskCreate(context);
    await db.tasksDao.insertTask(
      TasksCompanion.insert(
        title: _titleController.text.trim(),
        date: _date,
        startMinutes: TimeUtils.toMinutes(_startTime),
        endMinutes: TimeUtils.toMinutes(_endTime),
        priority: _priority,
        status: const Value(TaskStatus.pending),
        categoryId: Value(_categoryId),
        projectId: Value(_projectId),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: Theme.of(context).textTheme.titleMedium,
                  decoration: const InputDecoration(
                    hintText: 'ماذا تريد أن تنجز؟',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ),
              IconButton(
                onPressed: _save,
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ActionChip(
                  icon: Icons.calendar_today_outlined,
                  label: intl.DateFormat('d MMM', 'ar').format(_date),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
                _ActionChip(
                  icon: Icons.access_time,
                  label: TimeUtils.formatMinutes(TimeUtils.toMinutes(_startTime)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _startTime);
                    if (t != null) setState(() => _startTime = t);
                  },
                ),
                _ActionChip(
                  icon: Icons.flag_outlined,
                  label: _priorityLabel(_priority),
                  color: _priorityColor(_priority),
                  onTap: () {
                    setState(() {
                      _priority = TaskPriority.values[(_priority.index + 1) % TaskPriority.values.length];
                    });
                  },
                ),
                _CategoryPicker(
                  selectedId: _categoryId,
                  onSelected: (id) => setState(() => _categoryId = id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return 'عالية';
      case TaskPriority.medium: return 'متوسطة';
      case TaskPriority.low: return 'منخفضة';
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color?.withOpacity(0.3) ?? Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color ?? (isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: color ?? (isDark ? Colors.white70 : Colors.black54))),
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

  const _CategoryPicker({this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    return StreamBuilder<List<Category>>(
      stream: db.categoriesDao.watchAll(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        final selected = selectedId != null ? categories.firstWhere((c) => c.id == selectedId, orElse: () => categories.first) : null;
        
        return _ActionChip(
          icon: Icons.label_outline,
          label: selected?.name ?? 'تصنيف',
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: const Text('بدون تصنيف'), onTap: () { onSelected(null); Navigator.pop(context); }),
                  ...categories.map((c) => ListTile(
                    leading: Icon(Icons.circle, color: Color(c.color)),
                    title: Text(c.name),
                    onTap: () { onSelected(c.id); Navigator.pop(context); },
                  )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
