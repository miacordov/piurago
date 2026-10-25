import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../auth/auth_shell.dart';

/// Paso previo al mapa: pide activar la ubicación. Por ahora no solicita el
/// permiso real del dispositivo; ambos botones llevan a la lista de rutas.
class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  void _continuar(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.rutas);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text('UN ÚLTIMO PASO', style: AppText.eyebrow),
          const SizedBox(height: 12),
          const Text('Activa tu ubicación', style: AppText.title),
          const SizedBox(height: 10),
          const Text(
            'Te mostraremos los paraderos y líneas más cercanas a ti.',
            style: AppText.body,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _continuar(context),
            style: appFilledButtonStyle(),
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Activar ubicación'),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _continuar(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.text),
              child: const Text('Continuar sin activar ubicación'),
            ),
          ),
        ],
      ),
    );
  }
}
