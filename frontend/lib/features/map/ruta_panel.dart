import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui.dart';
import '../../data/models/paradero.dart';
import '../../data/models/ruta.dart';

/// Panel con el detalle de la ruta seleccionada y sus paraderos.
class RutaPanel extends StatelessWidget {
  const RutaPanel({super.key, required this.ruta, required this.paraderos});

  final Ruta ruta;
  final List<Paradero> paraderos;

  @override
  Widget build(BuildContext context) {
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
                    Text(ruta.descripcion ?? '', style: AppText.small),
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
          _CajaEta(eta: ruta.etaMinutos, paraderos: paraderos.length),
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
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.text,
              backgroundColor: AppColors.background,
              side: const BorderSide(color: Color(0xFFCFDBEC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Marcar como superada'),
          ),
        ],
      ),
    );
  }
}

class _CajaEta extends StatelessWidget {
  const _CajaEta({required this.eta, required this.paraderos});

  final int? eta;
  final int paraderos;

  @override
  Widget build(BuildContext context) {
    final minutos = eta == null ? '—' : '$eta min';
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
                const Text(
                  'Próxima unidad estimada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small,
                ),
                const SizedBox(height: 2),
                Text(
                  '$minutos · $paraderos paraderos',
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
