import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';

class WeeklyPlannerScreen extends StatelessWidget {
  const WeeklyPlannerScreen({super.key});

  static const days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

  static final Map<String, List<(String, Color)>> plan = {
    'سبت': [('تصميم', AppColors.primary)],
    'أحد': [('اجتماع', AppColors.accentBlue), ('تمرين', AppColors.accentGreen)],
    'اثنين': [('قراءة', AppColors.accentOrange)],
    'ثلاثاء': [('تصميم', AppColors.primary), ('تقرير', AppColors.accentPink)],
    'أربعاء': [],
    'خميس': [('اجتماع', AppColors.accentBlue)],
    'جمعة': [('راحة', AppColors.secondary)],
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'المخطط الأسبوعي',
      showNav: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right)),
              Text('19 - 25 مايو 2024', style: Theme.of(context).textTheme.titleSmall),
              IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left)),
            ],
          ),
          const SizedBox(height: 8),
          ...days.map((d) {
            final tasks = plan[d] ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 70, child: Text(d, style: Theme.of(context).textTheme.titleSmall)),
                    Expanded(
                      child: tasks.isEmpty
                          ? Text('لا توجد مهام', style: Theme.of(context).textTheme.bodySmall)
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tasks
                                  .map((t) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: t.$2.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                        child: Text(t.$1, style: TextStyle(color: t.$2, fontSize: 12, fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}
