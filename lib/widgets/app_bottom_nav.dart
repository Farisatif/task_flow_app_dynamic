import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  static const _items = [
    ('/', Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
    ('/today', Icons.today_outlined, Icons.today_rounded, 'اليوم'),
    ('/tasks', Icons.checklist_outlined, Icons.checklist_rounded, 'المهام'),
    ('/statistics', Icons.pie_chart_outline, Icons.pie_chart_rounded, 'الإحصائيات'),
    ('/more', Icons.grid_view_outlined, Icons.grid_view_rounded, 'المزيد'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.10 : 0.08);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;

              final activeColor = theme.colorScheme.primary;
              final inactiveColor = isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary;
              final color = selected ? activeColor : inactiveColor;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.go(item.$1),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.$4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? activeColor.withOpacity(isDark ? 0.16 : 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: selected ? 36 : 30,
                            height: selected ? 36 : 30,
                            decoration: BoxDecoration(
                              color: selected
                                  ? activeColor.withOpacity(isDark ? 0.20 : 0.14)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              selected ? item.$3 : item.$2,
                              color: color,
                              size: selected ? 22 : 21,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: color,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              height: 1.1,
                            ),
                            child: Text(
                              item.$4,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
