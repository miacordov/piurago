import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos de texto reutilizables.
class AppText {
  AppText._();

  static const eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.primary,
  );
  static const title = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w500,
    height: 1.15,
    color: AppColors.text,
  );
  static const heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: AppColors.textMuted,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const small = TextStyle(fontSize: 12, color: AppColors.textMuted);
}
