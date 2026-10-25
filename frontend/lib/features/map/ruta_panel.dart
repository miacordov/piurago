import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui.dart';
import '../../data/models/paradero.dart';
import '../../data/models/ruta.dart';

/// Panel con el detalle de la ruta seleccionada y sus paraderos.
class RutaPanel extends StatelessWidget {
  const RutaPanel({
    super.key,
    required this.ruta,
    required this.paraderos,
    this.onPlanificarViaje,
  });

  final Ruta ruta;
  final List<Paradero> paraderos;

  /// Si se indica, el panel muestra el botón "Planificar viaje".
  final VoidCallback? onPlanificarViaje;

  @override
  Widget build(BuildContext context) {
    final tramo = ruta.puntoInicio != null && ruta.puntoFinal != null
        ? '${ruta.puntoInicio} → ${ruta.puntoFinal}'
        : null;
    final detalle = [
      ruta.codigo,
      ruta.empresa,
      ruta.tipoServicio,
    ].whereType<String>().join(' · ');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RUTA SELECCIONADA', style: AppText.eyebrow),
                    const SizedBox(height: 6),
                    Text(
                      ruta.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [detalle, tramo ?? ruta.descripcion]
                          .whereType<String>()
                          .where((t) => t.isNotEmpty)
                          .join('\n'),
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blueTile,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_bus_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _CajaEta(ruta: ruta, paraderos: paraderos.length),
          if (onPlanificarViaje != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPlanificarViaje,
              style: appOutlinedButtonStyle(),
              icon: const Icon(Icons.alt_route, size: 18),
              label: const Text('Planificar viaje'),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Paraderos de la ruta',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text('${paraderos.length} paraderos', style: AppText.small),
            ],
          ),
          const SizedBox(height: 12),
          if (paraderos.isEmpty)
            const Text(
              'Esta ruta todavía no tiene paraderos cargados.',
              style: AppText.body,
            )
          else
            for (final (i, paradero) in paraderos.indexed)
              _FilaParadero(indice: i, paradero: paradero),
          if (ruta.recorrido != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Recorrido oficial (Municipalidad de Piura)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ruta.recorrido!.replaceFirst(
                RegExp(r'^Recorrido oficial \([^)]*\): '),
                '',
              ),
              style: AppText.body,
            ),
          ],
          if (ruta.lugaresDestacados.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Lugares por los que pasa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(ruta.lugaresDestacados.join(' · '), style: AppText.body),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => mostrarProximamente(context, 'Compartir la ruta'),
            style: appFilledButtonStyle(),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Compartir ruta'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                mostrarProximamente(context, 'Marcar la ruta como superada'),
            style: appOutlinedButtonStyle(),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Marcar como superada'),
          ),
        ],
      ),
    );
  }
}

class _CajaEta extends StatelessWidget {
  const _CajaEta({required this.ruta, required this.paraderos});

  final Ruta ruta;
  final int paraderos;

  @override
  Widget build(BuildContext context) {
    final eta = ruta.etaMinutos;
    // Sin ETA en vivo se muestran la frecuencia, el horario y el pasaje.
    final sinEta = eta == null && ruta.frecuenciaMinutos != null;
    final titulo = !ruta.activa
        ? 'Fuera de servicio'
        : sinEta
        ? 'Pasa cada ~${ruta.frecuenciaMinutos} min'
        : 'Próxima unidad estimada';
    final valor = sinEta || !ruta.activa
        ? [
            ruta.horario,
            if (ruta.pasaje != null) 'S/ ${ruta.pasaje!.toStringAsFixed(2)}',
            if (ruta.pasajeEstudiante != null)
              'Estudiante S/ ${ruta.pasajeEstudiante!.toStringAsFixed(2)}',
          ].whereType<String>().join(' · ')
        : '${eta == null ? '—' : '$eta min'} · $paraderos paraderos';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.etaBox,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small,
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaParadero extends StatelessWidget {
  const _FilaParadero({required this.indice, required this.paradero});

  final int indice;
  final Paradero paradero;

  @override
  Widget build(BuildContext context) {
    final primero = indice == 0;
    final minutos = paradero.etaMinutos;
    final etiqueta = minutos == null
        ? ''
        : (minutos == 0 ? 'Ahora' : '$minutos min');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primero ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              '${indice + 1}',
              style: TextStyle(
                fontSize: 11,
                color: primero ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              paradero.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: primero ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(etiqueta, style: AppText.small),
        ],
      ),
    );
  }
}
