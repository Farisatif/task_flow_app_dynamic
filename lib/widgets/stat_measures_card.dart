import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// بطاقة تعرض مجموعة من المقاييس الإحصائية (المتوسط، الوسيط، المنوال...)
/// كل مقياس عبارة عن تسمية + قيمة، مرتبة في شبكة مرنة (Wrap).
class StatMeasuresCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<StatMeasure> measures;

  const StatMeasuresCard({super.key, required this.title, this.subtitle, required this.measures});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: measures.map((m) => _measureChip(context, m)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _measureChip(BuildContext context, StatMeasure m) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            m.value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: m.color ?? AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(m.label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class StatMeasure {
  final String label;
  final String value;
  final Color? color;

  const StatMeasure({required this.label, required this.value, this.color});
}
