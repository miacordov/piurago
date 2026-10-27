import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/ruta.dart';

/// Modal de viaje finalizado (referencia visual 07-viaje-finalizado.png).
/// Muestra las estadísticas finales del recorrido y confirma que se detuvo el GPS.
class ViajeFinalizadoDialog extends StatelessWidget {
  const ViajeFinalizadoDialog({
    super.key,
    required this.ruta,
    required this.paraderosVisitados,
    this.duracionMinutos = 14,
  });

  final Ruta ruta;
  final int paraderosVisitados;
  final int duracionMinutos;

  static Future<void> mostrar(
    BuildContext context, {
    required Ruta ruta,
    required int paraderosVisitados,
    int duracionMinutos = 14,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ViajeFinalizadoDialog(
        ruta: ruta,
        paraderosVisitados: paraderosVisitados,
        duracionMinutos: duracionMinutos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.greenTile,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 32,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Viaje finalizado',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ruta.codigo} · ${ruta.nombre}',
                textAlign: TextAlign.center,
                style: AppText.small.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _Estadistica(
                        titulo: 'DURACIÓN',
                        valor: '$duracionMinutos min',
                        icono: Icons.timer_outlined,
                      ),
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    Expanded(
                      child: _Estadistica(
                        titulo: 'PARADEROS',
                        valor: '$paraderosVisitados',
                        icono: Icons.pin_drop_outlined,
                      ),
                    ),
                    if (ruta.pasaje != null) ...[
                      Container(width: 1, height: 32, color: AppColors.border),
                      Expanded(
                        child: _Estadistica(
                          titulo: 'PASAJE',
                          valor: 'S/ ${ruta.pasaje!.toStringAsFixed(2)}',
                          icono: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Ya no estás compartiendo tu ubicación.',
                      style: AppText.small.copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: appFilledButtonStyle(),
                  child: const Text('Volver al mapa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Estadistica extends StatelessWidget {
  const _Estadistica({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
