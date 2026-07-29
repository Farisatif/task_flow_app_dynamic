import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

IconData _kindIcon(AttachmentKind kind) {
  switch (kind) {
    case AttachmentKind.image:
      return Icons.image_outlined;
    case AttachmentKind.pdf:
      return Icons.picture_as_pdf_outlined;
    case AttachmentKind.text:
      return Icons.description_outlined;
    case AttachmentKind.doc:
      return Icons.article_outlined;
    case AttachmentKind.chart:
      return Icons.bar_chart_outlined;
    case AttachmentKind.presentation:
      return Icons.slideshow_outlined;
  }
}

Color _kindColor(AttachmentKind kind) {
  switch (kind) {
    case AttachmentKind.image:
      return const Color(0xFF5B9DF9);
    case AttachmentKind.pdf:
      return const Color(0xFFFF6B81);
    case AttachmentKind.text:
      return const Color(0xFF4CD787);
    case AttachmentKind.doc:
      return const Color(0xFF7B6FF0);
    case AttachmentKind.chart:
      return const Color(0xFFFFB258);
    case AttachmentKind.presentation:
      return const Color(0xFFFF7EB3);
  }
}

String _kindLabel(AttachmentKind kind) {
  switch (kind) {
    case AttachmentKind.image:
      return 'صورة';
    case AttachmentKind.pdf:
      return 'PDF';
    case AttachmentKind.text:
      return 'نص';
    case AttachmentKind.doc:
      return 'مستند';
    case AttachmentKind.chart:
      return 'رسم بياني';
    case AttachmentKind.presentation:
      return 'عرض تقديمي';
  }
}

String _sizeLabel(int bytes) {
  if (bytes <= 0) return '-';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

enum _AttachmentFilter { all, image, pdf, text, doc, chart, presentation }

extension on _AttachmentFilter {
  String get label {
    switch (this) {
      case _AttachmentFilter.all:
        return 'الكل';
      case _AttachmentFilter.image:
        return 'صور';
      case _AttachmentFilter.pdf:
        return 'PDF';
      case _AttachmentFilter.text:
        return 'نصوص';
      case _AttachmentFilter.doc:
        return 'مستندات';
      case _AttachmentFilter.chart:
        return 'رسوم';
      case _AttachmentFilter.presentation:
        return 'عروض';
    }
  }

  AttachmentKind? get kind {
    switch (this) {
      case _AttachmentFilter.all:
        return null;
      case _AttachmentFilter.image:
        return AttachmentKind.image;
      case _AttachmentFilter.pdf:
        return AttachmentKind.pdf;
      case _AttachmentFilter.text:
        return AttachmentKind.text;
      case _AttachmentFilter.doc:
        return AttachmentKind.doc;
      case _AttachmentFilter.chart:
        return AttachmentKind.chart;
      case _AttachmentFilter.presentation:
        return AttachmentKind.presentation;
    }
  }
}

class AttachmentsScreen extends StatefulWidget {
  const AttachmentsScreen({super.key});

  @override
  State<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _AttachmentFilter _filter = _AttachmentFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Attachment> _applyFilters(List<Attachment> attachments) {
    final query = _searchController.text.trim().toLowerCase();
    final selectedKind = _filter.kind;

    return attachments.where((attachment) {
      final matchesQuery = query.isEmpty ||
          attachment.name.toLowerCase().contains(query);

      final matchesKind =
          selectedKind == null ? true : attachment.kind == selectedKind;

      return matchesQuery && matchesKind;
    }).toList();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppDatabase db,
    Attachment attachment,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف المرفق'),
        content: Text('هل تريد حذف "${attachment.name}"؟'),
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

    if (shouldDelete == true) {
      await db.attachmentsDao.deleteAttachment(attachment.id);
    }
  }

  Future<void> _showAddSheet(BuildContext context, AppDatabase db) async {
    final nameController = TextEditingController();
    final sizeController = TextEditingController(text: '0');
    AttachmentKind selectedKind = AttachmentKind.doc;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إضافة مرفق',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'أضف ملفًا جديدًا وحدد نوعه بسرعة',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'اسم الملف',
                        hintText: 'مثال: خطة المشروع النهائية',
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
                    DropdownButtonFormField<AttachmentKind>(
                      value: selectedKind,
                      decoration: InputDecoration(
                        labelText: 'نوع الملف',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: AttachmentKind.values
                          .map(
                            (kind) => DropdownMenuItem(
                              value: kind,
                              child: Row(
                                children: [
                                  Icon(
                                    _kindIcon(kind),
                                    size: 18,
                                    color: _kindColor(kind),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(_kindLabel(kind)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedKind = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sizeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'الحجم بالبايت',
                        hintText: 'مثال: 2048',
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
                    _PreviewCard(
                      name: nameController.text.trim().isEmpty
                          ? 'معاينة الملف'
                          : nameController.text.trim(),
                      kind: selectedKind,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
                              final name = nameController.text.trim();
                              final size =
                                  int.tryParse(sizeController.text.trim()) ?? 0;

                              if (name.isEmpty) return;

                              await db.attachmentsDao.insertAttachment(
                                AttachmentsCompanion.insert(
                                  name: name,
                                  kind: selectedKind,
                                  sizeBytes: Value(size),
                                ),
                              );

                              if (!mounted) return;
                              Navigator.of(sheetContext).pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
            );
          },
        );
      },
    );

    nameController.dispose();
    sizeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'المرفقات',
      showNav: false,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddSheet(context, db),
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text(
          'مرفق جديد',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Attachment>>(
        stream: db.attachmentsDao.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل المرفقات',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final allAttachments = snapshot.data ?? [];
          final attachments = _applyFilters(allAttachments)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final totalCount = allAttachments.length;
          final totalSize =
              allAttachments.fold<int>(0, (sum, a) => sum + a.sizeBytes);
          final latestDate = allAttachments.isEmpty
              ? null
              : allAttachments
                  .map((a) => a.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b);

          final kindCounts = {
            for (final kind in AttachmentKind.values)
              kind: allAttachments.where((a) => a.kind == kind).length,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeroCard(
                totalCount: totalCount,
                totalSize: _sizeLabel(totalSize),
                latestDate: latestDate == null
                    ? 'لا يوجد'
                    : intl.DateFormat('d MMM yyyy', 'ar').format(latestDate),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _MetricCard(
                    title: 'إجمالي المرفقات',
                    value: '$totalCount',
                    icon: Icons.attach_file_rounded,
                    color: AppColors.primary,
                  ),
                  _MetricCard(
                    title: 'إجمالي الحجم',
                    value: _sizeLabel(totalSize),
                    icon: Icons.storage_rounded,
                    color: AppColors.accentBlue,
                  ),
                  _MetricCard(
                    title: 'أحدث ملف',
                    value: latestDate == null
                        ? '-'
                        : intl.DateFormat('d MMM', 'ar').format(latestDate),
                    icon: Icons.schedule_rounded,
                    color: AppColors.accentGreen,
                  ),
                  _MetricCard(
                    title: 'أنواع مفعّلة',
                    value: '${kindCounts.values.where((c) => c > 0).length}',
                    icon: Icons.category_rounded,
                    color: AppColors.accentYellow,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'تصفية سريعة',
                subtitle: 'اختَر نوع المرفق الذي تريد عرضه',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AttachmentKind.values.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final selected = _filter == _AttachmentFilter.all;
                      return ChoiceChip(
                        label: const Text('الكل'),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _filter = _AttachmentFilter.all);
                        },
                      );
                    }

                    final kind = AttachmentKind.values[index - 1];
                    final selected = _filter.kind == kind;
                    final count = kindCounts[kind] ?? 0;

                    return ChoiceChip(
                      label: Text('${_kindLabel(kind)} ($count)'),
                      selected: selected,
                      avatar: Icon(
                        _kindIcon(kind),
                        size: 18,
                        color: selected ? Colors.white : _kindColor(kind),
                      ),
                      selectedColor: _kindColor(kind),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _filter = switch (kind) {
                            AttachmentKind.image => _AttachmentFilter.image,
                            AttachmentKind.pdf => _AttachmentFilter.pdf,
                            AttachmentKind.text => _AttachmentFilter.text,
                            AttachmentKind.doc => _AttachmentFilter.doc,
                            AttachmentKind.chart => _AttachmentFilter.chart,
                            AttachmentKind.presentation =>
                              _AttachmentFilter.presentation,
                          };
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'قائمة المرفقات',
                subtitle: 'آخر الملفات المضافة',
              ),
              const SizedBox(height: 10),
              if (attachments.isEmpty)
                _EmptyState(
                  onAdd: () => _showAddSheet(context, db),
                  filterKind: _filter.kind,
                )
              else
                ...attachments.map(
                  (attachment) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _showDetailsSheet(context, attachment),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kindColor(attachment.kind)
                                .withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _kindIcon(attachment.kind),
                            color: _kindColor(attachment.kind),
                          ),
                        ),
                        title: Text(
                          attachment.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${_kindLabel(attachment.kind)} · ${_sizeLabel(attachment.sizeBytes)} · ${intl.DateFormat('d MMM yyyy', 'ar').format(attachment.createdAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.priorityHigh,
                          ),
                          onPressed: () => _confirmDelete(
                            context,
                            db,
                            attachment,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, Attachment attachment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final color = _kindColor(attachment.kind);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_kindIcon(attachment.kind), color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _kindLabel(attachment.kind),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _detailRow(sheetContext, 'الحجم', _sizeLabel(attachment.sizeBytes)),
              const SizedBox(height: 8),
              _detailRow(
                sheetContext,
                'تاريخ الإنشاء',
                intl.DateFormat('d MMMM yyyy', 'ar')
                    .format(attachment.createdAt),
              ),
              const SizedBox(height: 8),
              _detailRow(sheetContext, 'النوع', _kindLabel(attachment.kind)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int totalCount;
  final String totalSize;
  final String latestDate;

  const _HeroCard({
    required this.totalCount,
    required this.totalSize,
    required this.latestDate,
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
                child: Icon(Icons.folder_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'مركز المرفقات الذكي',
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
            'أدر ملفاتك، استعرضها بسرعة، وتابع حجمها وتاريخها من مكان واحد.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  icon: Icons.attach_file_rounded,
                  label: 'عدد الملفات',
                  value: '$totalCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.storage_rounded,
                  label: 'إجمالي الحجم',
                  value: totalSize,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.schedule_rounded,
                  label: 'آخر إضافة',
                  value: latestDate,
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
  final VoidCallback onAdd;
  final AttachmentKind? filterKind;

  const _EmptyState({
    required this.onAdd,
    required this.filterKind,
  });

  @override
  Widget build(BuildContext context) {
    final isFiltered = filterKind != null;

    return Padding(
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
              Icons.folder_open_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered ? 'لا توجد مرفقات لهذا النوع' : 'لا توجد مرفقات بعد',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'جرّب اختيار نوع آخر أو أضف مرفقًا جديدًا.'
                : 'ابدأ برفع أول ملف لتنظيم مكتبتك.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مرفق'),
          ),
        ],
      ),
    );
  }
}
