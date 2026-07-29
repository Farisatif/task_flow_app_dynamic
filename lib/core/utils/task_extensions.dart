import 'package:flutter/material.dart';

import '../database/tables.dart';
import 'time_utils.dart';

extension TaskUiExtensions on Task {
  Color priorityColor() {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFFF6B81);
      case TaskPriority.medium:
        return const Color(0xFFFFB258);
      case TaskPriority.low:
        return const Color(0xFF4CD787);
      default:
        return const Color(0xFF4CD787);
    }
  }

  String priorityLabel() {
    switch (priority) {
      case TaskPriority.high:
        return 'عالية';
      case TaskPriority.medium:
        return 'متوسطة';
      case TaskPriority.low:
        return 'منخفضة';
      default:
        return 'متوسطة';
    }
  }

  String statusLabel() {
    switch (status) {
      case TaskStatus.completed:
        return 'مكتملة';
      case TaskStatus.inProgress:
        return 'جارية';
      case TaskStatus.pending:
        return 'منتظرة';
      default:
        return 'منتظرة';
    }
  }

  bool get isDone => status == TaskStatus.completed;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isPending => status == TaskStatus.pending;

  String get timeRange => TimeUtils.rangeLabel(startMinutes, endMinutes);
}
