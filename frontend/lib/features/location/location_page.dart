import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../data/ubicacion/servicio_ubicacion.dart';
import '../auth/auth_shell.dart';

/// Paso previo al mapa: pide activar la ubicación real del dispositivo (Android/web)
/// utilizando [ServicioUbicacion]. Permite también continuar manualmente sin GPS.
class LocationPage extends StatelessWidget {
  const LocationPage({
    super.key,
    this.servicioUbicacion = const GeolocatorServicioUbicacion(),
  });

  final ServicioUbicacion servicioUbicacion;

  void _continuar(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.rutas);
  }

  Future<void> _activarUbicacion(BuildContext context) async {
    final estado = await servicioUbicacion.solicitarPermiso();
    if (!context.mounted) return;

    if (estado == EstadoPermisoUbicacion.servicioDesactivado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El GPS de tu dispositivo está desactivado.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (estado == EstadoPermisoUbicacion.denegado ||
        estado == EstadoPermisoUbicacion.denegadoParaSiempre) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permiso no concedido. Podrás buscar rutas manualmente.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    _continuar(context);
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
            onPressed: () => _activarUbicacion(context),
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
