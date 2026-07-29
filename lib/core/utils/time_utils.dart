import 'package:flutter/material.dart';

/// تحويلات مساعدة بين TimeOfDay ودقائق اليوم
class TimeUtils {
  TimeUtils._();

  static int toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static TimeOfDay fromMinutes(int minutes) {
    final normalized = minutes % (24 * 60);
    final safe = normalized < 0 ? normalized + (24 * 60) : normalized;

    return TimeOfDay(
      hour: safe ~/ 60,
      minute: safe % 60,
    );
  }

  static String formatMinutes(int minutes) {
    final time = fromMinutes(minutes);
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String rangeLabel(int start, int end) {
    return '${formatMinutes(start)} - ${formatMinutes(end)}';
  }

  static int clampMinutes(int minutes) {
    if (minutes < 0) return 0;
    if (minutes > 24 * 60 - 1) return 24 * 60 - 1;
    return minutes;
  }
}
