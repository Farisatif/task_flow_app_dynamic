import 'dart:math';

/// دوال إحصائية عامة (المتوسط، الوسيط، المنوال، الانحراف المعياري، المدى...)
/// تُستخدم لتحليل بيانات المهام والتركيز والعادات في شاشات الإحصائيات.
/// لا تعتمد على أي حزمة خارجية حتى تبقى متوافقة مع كل إصدارات المشروع.
class StatsUtils {
  StatsUtils._();

  /// المتوسط الحسابي
  static double mean(List<num> values) {
    if (values.isEmpty) return 0;
    final sum = values.fold<num>(0, (a, b) => a + b);
    return sum / values.length;
  }

  /// الوسيط: القيمة الوسطى بعد الترتيب (أو متوسط القيمتين الوسطيتين)
  static double median(List<num> values) {
    if (values.isEmpty) return 0;
    final sorted = List<num>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[mid].toDouble();
    }
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  /// المنوال: القيمة الأكثر تكرارًا. عند عدم وجود أي تكرار حقيقي تُعاد null.
  /// عند تعادل عدة قيم بنفس أعلى تكرار، تُعاد أصغرها.
  static double? mode(List<num> values) {
    if (values.isEmpty) return null;

    final counts = <num, int>{};
    for (final v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }

    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    if (maxCount <= 1) return null; // كل القيم فريدة، لا يوجد منوال حقيقي

    final candidates = counts.entries.where((e) => e.value == maxCount).map((e) => e.key).toList()..sort();
    return candidates.first.toDouble();
  }

  /// التباين (Variance)
  static double variance(List<num> values) {
    if (values.length < 2) return 0;
    final m = mean(values);
    final sumSquares = values.fold<double>(0, (sum, v) => sum + (v - m) * (v - m));
    return sumSquares / values.length;
  }

  /// الانحراف المعياري (Standard Deviation)
  static double standardDeviation(List<num> values) => sqrt(variance(values));

  /// المدى: الفرق بين أكبر وأصغر قيمة
  static num range(List<num> values) {
    if (values.isEmpty) return 0;
    final sorted = List<num>.from(values)..sort();
    return sorted.last - sorted.first;
  }

  static num minOf(List<num> values) => values.isEmpty ? 0 : values.reduce(min);

  static num maxOf(List<num> values) => values.isEmpty ? 0 : values.reduce(max);
}
