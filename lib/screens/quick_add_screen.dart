import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final TextEditingController _quickTitleController = TextEditingController();

  static const List<_QuickItem> _items = [
    _QuickItem(
      title: 'مهمة',
      icon: Icons.check_box_outlined,
      color: AppColors.primary,
      route: '/task-form',
      subtitle: 'إنشاء مهمة جديدة',
    ),
    _QuickItem(
      title: 'مشروع',
      icon: Icons.folder_outlined,
      color: AppColors.accentBlue,
      route: '/projects',
      subtitle: 'إضافة مشروع',
    ),
    _QuickItem(
      title: 'تذكير',
      icon: Icons.notifications_outlined,
      color: AppColors.priorityHigh,
      route: '/reminders',
      subtitle: 'ضبط تذكير',
    ),
    _QuickItem(
      title: 'ملاحظة',
      icon: Icons.sticky_note_2_outlined,
      color: AppColors.accentOrange,
      route: '/notes',
      subtitle: 'تسجيل فكرة',
    ),
    _QuickItem(
      title: 'هدف',
      icon: Icons.flag_outlined,
      color: AppColors.accentGreen,
      route: '/goals',
      subtitle: 'إضافة هدف',
    ),
    _QuickItem(
      title: 'عادة',
      icon: Icons.repeat_rounded,
      color: AppColors.accentPink,
      route: '/habits',
      subtitle: 'بناء عادة',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _quickTitleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _quickTitleController.removeListener(_onTitleChanged);
    _quickTitleController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (mounted) setState(() {});
  }

  void _openRoute(String route, {String? initialTitle}) {
    final router = GoRouter.of(context);

    Navigator.of(context).pop();
    router.push(
      route,
      extra: initialTitle?.trim().isEmpty == true ? null : initialTitle!.trim(),
    );
  }

  void _submitQuickTask() {
    final title = _quickTitleController.text.trim();
    if (title.isEmpty) return;

    _openRoute('/task-form', initialTitle: title);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _quickTitleController.text.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.45),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إضافة سريعة',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _submitQuickTask,
                      child: const Text(
                        'إضافة المهمة',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
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
                      Text(
                        'اختر نوع الإضافة',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أضف عنصرًا جديدًا بسرعة أو ابدأ من مهمة مباشرة.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          return _QuickActionCard(
                            item: item,
                            onTap: () => _openRoute(
                              item.route,
                              initialTitle: _quickTitleController.text,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _quickTitleController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitQuickTask(),
                        decoration: InputDecoration(
                          hintText: 'أو اكتب عنوان مهمة مباشرة...',
                          prefixIcon: const Icon(Icons.edit_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: hasText
                                  ? AppColors.primary
                                  : theme.hintColor,
                            ),
                            onPressed: _submitQuickTask,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.35),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _QuickPreview(
                        title: hasText ? _quickTitleController.text.trim() : 'اكتب عنوانًا لتبدأ',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
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
                              onPressed: _submitQuickTask,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('إنشاء مهمة'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickItem item;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.color.withOpacity(0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickPreview extends StatelessWidget {
  final String title;

  const _QuickPreview({
    required this.title,
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
              Icons.task_alt_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final String subtitle;

  const _QuickItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    required this.subtitle,
  });
}
