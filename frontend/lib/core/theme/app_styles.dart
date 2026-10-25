import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Campo de texto con el estilo de PiuraGo (alto de 48 px, borde de 8 px).
InputDecoration appInputDecoration({
  required String hint,
  required IconData icon,
  Color fill = AppColors.field,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
    prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
    filled: true,
    fillColor: fill,
    hoverColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.danger, width: 1.5),
    ),
  );
}

/// Botón principal: ocupa todo el ancho disponible y mide 48 px de alto.
ButtonStyle appFilledButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
  );
}

/// Botón pequeño, para usar dentro de tarjetas.
ButtonStyle appCompactButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 36),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );
}

/// Botón secundario: fondo claro con borde, del mismo alto que el principal.
ButtonStyle appOutlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    foregroundColor: AppColors.text,
    backgroundColor: AppColors.background,
    side: const BorderSide(color: AppColors.secondaryBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );
}
