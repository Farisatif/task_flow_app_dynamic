import 'package:flutter/material.dart';

import '../database/database.dart';
import 'time_utils.dart';

extension TaskUiExtensions on Task {
  String _normalize(Object? value) {
    final raw = value?.toString().toLowerCase() ?? '';
    return raw.contains('.') ? raw.split('.').last : raw;
  }

  Color priorityColor() {
    final p = _normalize(priority);

    if (p.contains('high') || p.contains('عالية') || p.contains('مرتفع')) {
      return const Color(0xFFFF6B81);
    }
    if (p.contains('medium') || p.contains('normal') || p.contains('متوسطة')) {
      return const Color(0xFFFFB258);
    }
    if (p.contains('low') || p.contains('منخفض')) {
      return const Color(0xFF4CD787);
    }
    return const Color(0xFF4CD787);
  }

  String priorityLabel() {
    final p = _normalize(priority);

    if (p.contains('high') || p.contains('عالية') || p.contains('مرتفع')) {
      return 'عالية';
    }
    if (p.contains('medium') || p.contains('normal') || p.contains('متوسطة')) {
      return 'متوسطة';
    }
    if (p.contains('low') || p.contains('منخفض')) {
      return 'منخفضة';
    }
    return 'متوسطة';
  }

  String statusLabel() {
    final s = _normalize(status);

    if (s.contains('completed') || s.contains('مكتملة')) {
      return 'مكتملة';
    }
    if (s.contains('inprogress') || s.contains('جارية')) {
      return 'جارية';
    }
    if (s.contains('pending') || s.contains('منتظرة')) {
      return 'منتظرة';
    }
    return 'منتظرة';
  }

  bool get isDone => _normalize(status).contains('completed') || _normalize(status).contains('مكتملة');
  bool get isInProgress => _normalize(status).contains('inprogress') || _normalize(status).contains('جارية');
  bool get isPending => _normalize(status).contains('pending') || _normalize(status).contains('منتظرة');

  String get timeRange => TimeUtils.rangeLabel(startMinutes, endMinutes);
}
