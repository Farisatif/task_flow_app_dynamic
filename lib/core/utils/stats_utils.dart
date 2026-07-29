import 'dart:math' as math;

/// دوال إحصائية عامة
/// تُستخدم لتحليل بيانات المهام والتركيز والعادات في شاشات الإحصائيات.
/// لا تعتمد على أي حزمة خارجية حتى تبقى متوافقة مع المشروع.
class StatsUtils {
  StatsUtils._();

  static List<double> _toDoubleList(List<num> values) {
    return values.map((v) => v.toDouble()).toList(growable: false);
  }

  /// مجموع القيم
  static double sum(List<num> values) {
    if (values.isEmpty) return 0;
    return values.fold<double>(0, (a, b) => a + b.toDouble());
  }

  /// المتوسط الحسابي
  static double mean(List<num> values) {
    if (values.isEmpty) return 0;
    return sum(values) / values.length;
  }

  /// الوسيط: القيمة الوسطى بعد الترتيب
  static double median(List<num> values) {
    if (values.isEmpty) return 0;

    final sorted = _toDoubleList(values)..sort();
    final mid = sorted.length ~/ 2;

    if (sorted.length.isOdd) {
      return sorted[mid];
    }

    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  /// المنوال: القيمة الأكثر تكرارًا.
  /// عند عدم وجود تكرار حقيقي تُعاد null.
  /// عند التعادل تُعاد أصغر قيمة.
  static double? mode(List<num> values) {
    if (values.isEmpty) return null;

    final counts = <double, int>{};
    for (final v in values) {
      final key = v.toDouble();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    var maxCount = 0;
    for (final count in counts.values) {
      if (count > maxCount) maxCount = count;
    }

    if (maxCount <= 1) return null;

    final candidates = counts.entries
        .where((e) => e.value == maxCount)
        .map((e) => e.key)
        .toList()
      ..sort();

    return candidates.first;
  }

  /// التباين (Population Variance)
  static double variance(List<num> values) {
    if (values.length < 2) return 0;

    final m = mean(values);
    final sumSquares = values.fold<double>(
      0,
      (sum, v) {
        final d = v.toDouble() - m;
        return sum + (d * d);
      },
    );

    return sumSquares / values.length;
  }

  /// الانحراف المعياري
  static double standardDeviation(List<num> values) {
    return math.sqrt(variance(values));
  }

  /// المدى: الفرق بين أكبر وأصغر قيمة
  static double range(List<num> values) {
    if (values.isEmpty) return 0;

    final sorted = _toDoubleList(values)..sort();
    return sorted.last - sorted.first;
  }

  static double minOf(List<num> values) {
    if (values.isEmpty) return 0;
    return values.map((v) => v.toDouble()).reduce(math.min);
  }

  static double maxOf(List<num> values) {
    if (values.isEmpty) return 0;
    return values.map((v) => v.toDouble()).reduce(math.max);
  }
}
