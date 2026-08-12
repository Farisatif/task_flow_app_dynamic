import 'package:flutter/material.dart';

/// لوحة حضرية هادئة: أزرق ليلي للإجراء، نعناعي للإنجاز، وكهرماني للتنبيه.
class AppColors {
  AppColors._();

  // الألوان الأساسية
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF14B8A6);

  // ألوان مساعدة
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentYellow = Color(0xFFFACC15);

  // أولوية المهام
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  // الوضع النهاري
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6EAF0);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // الوضع الليلي
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111C2E);
  static const Color darkCard = Color(0xFF162235);
  static const Color darkBorder = Color(0xFF25344A);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // التدرج الرئيسي
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ألوان الرسوم البيانية
  static const List<Color> chartPalette = [
    accentBlue,
    accentGreen,
    accentOrange,
    accentPink,
    primary,
    accentYellow,
  ];
}
