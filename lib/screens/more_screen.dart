import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_SectionData> _sections = [
    _SectionData(
      title: 'التخطيط الاستراتيجي',
      items: [
        _MenuItem(
          title: 'الأهداف',
          icon: Icons.flag_outlined,
          color: AppColors.primary,
          route: '/goals',
        ),
        _MenuItem(
          title: 'العادات',
          icon: Icons.repeat_rounded,
          color: AppColors.accentGreen,
          route: '/habits',
        ),
        _MenuItem(
          title: 'المشاريع',
          icon: Icons.folder_outlined,
          color: AppColors.accentBlue,
          route: '/projects',
        ),
        _MenuItem(
          title: 'التصنيفات',
          icon: Icons.category_outlined,
          color: AppColors.accentPink,
          route: '/categories',
        ),
        _MenuItem(
          title: 'المخطط الأسبوعي',
          icon: Icons.view_week_outlined,
          color: AppColors.secondary,
          route: '/weekly-planner',
        ),
      ],
    ),
    _SectionData(
      title: 'التحفيز والتحليل',
      items: [
        _MenuItem(
          title: 'لوحة التركيز',
          icon: Icons.dashboard_customize_outlined,
          color: AppColors.accentOrange,
          route: '/focus-dashboard',
        ),
        _MenuItem(
          title: 'تحليل الإنتاجية',
          icon: Icons.trending_up_rounded,
          color: AppColors.primary,
          route: '/productivity-analysis',
        ),
        _MenuItem(
          title: 'تقارير الأداء',
          icon: Icons.assessment_outlined,
          color: AppColors.accentBlue,
          route: '/performance-reports',
        ),
        _MenuItem(
          title: 'الإنجازات',
          icon: Icons.emoji_events_outlined,
          color: AppColors.accentYellow,
          route: '/achievements',
        ),
      ],
    ),
    _SectionData(
      title: 'الأدوات المساعدة',
      items: [
        _MenuItem(
          title: 'الملاحظات',
          icon: Icons.sticky_note_2_outlined,
          color: AppColors.accentPink,
          route: '/notes',
        ),
        _MenuItem(
          title: 'المرفقات',
          icon: Icons.attach_file_rounded,
          color: AppColors.accentGreen,
          route: '/attachments',
        ),
        _MenuItem(
          title: 'التذكيرات',
          icon: Icons.notifications_active_outlined,
          color: AppColors.priorityHigh,
          route: '/reminders',
        ),
      ],
    ),
    _SectionData(
      title: 'إدارة التطبيق',
      items: [
        _MenuItem(
          title: 'الملف الشخصي',
          icon: Icons.person_outline_rounded,
          color: AppColors.primary,
          route: '/profile',
        ),
        _MenuItem(
          title: 'الإعدادات',
          icon: Icons.settings_outlined,
          color: AppColors.accentBlue,
          route: '/settings',
        ),
        _MenuItem(
          title: 'النسخ الاحتياطي والمزامنة',
          icon: Icons.cloud_sync_outlined,
          color: AppColors.accentGreen,
          route: '/backup-sync',
        ),
        _MenuItem(
          title: 'البحث والفلترة',
          icon: Icons.manage_search_rounded,
          color: AppColors.accentOrange,
          route: '/search',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SectionData> get _filteredSections {
    if (_query.trim().isEmpty) return _sections;

    final q = _query.trim().toLowerCase();

    return _sections
        .map(
          (section) => _SectionData(
            title: section.title,
            items: section.items
                .where((item) => item.title.toLowerCase().contains(q))
                .toList(),
          ),
        )
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  int get _totalItems =>
      _sections.fold<int>(0, (sum, section) => sum + section.items.length);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredSections = _filteredSections;
    final visibleItems = filteredSections.fold<int>(
      0,
      (sum, section) => sum + section.items.length,
    );

    return AppScaffold(
      title: 'المزيد',
      navIndex: 4,
      showNav: true,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HeaderCard(
              totalItems: _totalItems,
              visibleItems: visibleItems,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث عن صفحة أو أداة...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
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
            const SizedBox(height: 16),
            if (filteredSections.isEmpty)
              _EmptyState(
                title: 'لا توجد نتائج',
                subtitle: 'جرّب كلمة بحث مختلفة',
                icon: Icons.search_off_rounded,
              )
            else
              ...filteredSections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _SectionBlock(section: section),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int totalItems;
  final int visibleItems;

  const _HeaderCard({
    required this.totalItems,
    required this.visibleItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hiddenItems = totalItems - visibleItems;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.dashboard_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز التحكم',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كل الأدوات المهمة في مكان واحد',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$visibleItems',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  hiddenItems > 0 ? 'ظاهر' : 'كلها',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _SectionBlock extends StatelessWidget {
  final _SectionData section;

  const _SectionBlock({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: section.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final item = section.items[index];
            return _MenuCard(item: item);
          },
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(item.route),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionData {
  final String title;
  final List<_MenuItem> items;

  const _SectionData({
    required this.title,
    required this.items,
  });
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}
