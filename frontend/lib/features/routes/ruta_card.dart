import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/ruta.dart';

/// Fila de una línea en la lista de rutas, como en la lista de líneas de
/// Moovit: el código con su color, el nombre, la empresa y el tipo, por
/// dónde pasa, y a la derecha la frecuencia y el pasaje. Tocarla abre la
/// línea en el mapa.
class RutaCard extends StatelessWidget {
  const RutaCard({super.key, required this.ruta, this.lugarCoincidente});

  final Ruta ruta;

  /// Lugar que coincidió con la búsqueda ("Pasa por Mercado Modelo"). Si no
  /// hay, se muestran los primeros lugares por los que pasa.
  final String? lugarCoincidente;

  @override
  Widget build(BuildContext context) {
    final colores = ColoresDeTono.de(ruta.tono);
    final detalle = [
      ruta.empresa,
      ruta.tipoServicio,
    ].whereType<String>().join(' · ');
    final lugares = ruta.lugaresDestacados.isNotEmpty
        ? ruta.lugaresDestacados.take(3).join(' · ')
        : [ruta.puntoInicio, ruta.puntoFinal].whereType<String>().join(' → ');
    final pasaPor = lugarCoincidente != null
        ? 'Pasa por $lugarCoincidente'
        : lugares;
    final (servicio, colorServicio) = !ruta.activa
        ? ('Fuera de servicio', AppColors.danger)
        : ruta.etaMinutos != null
        ? ('${ruta.etaMinutos} min', AppColors.primary)
        : ruta.frecuenciaMinutos != null
        ? ('cada ~${ruta.frecuenciaMinutos} min', AppColors.text)
        : (null, AppColors.text);
    final pasaje = ruta.pasaje;

    return Semantics(
      button: true,
      label: 'Ver ${ruta.codigo ?? ruta.nombre} en el mapa',
      child: Material(
        color: ruta.activa ? AppColors.surface : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.mapa, arguments: ruta.idRuta),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colores.fondo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ruta.codigo ?? '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colores.icono,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruta.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label,
                      ),
                      if (detalle.isNotEmpty)
                        Text(
                          detalle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small,
                        ),
                      if (pasaPor.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          pasaPor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: lugarCoincidente != null
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (servicio != null)
                        Text(
                          servicio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorServicio,
                          ),
                        ),
                      if (pasaje != null)
                        Text(
                          'S/ ${pasaje.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small,
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Colores de la ficha de una línea según su tono.
class ColoresDeTono {
  const ColoresDeTono(this.fondo, this.icono);

  final Color fondo;
  final Color icono;

  static ColoresDeTono de(RutaTono tono) {
    return switch (tono) {
      RutaTono.azul => const ColoresDeTono(
        AppColors.blueTile,
        AppColors.primary,
      ),
      RutaTono.verde => const ColoresDeTono(
        AppColors.greenTile,
        AppColors.success,
      ),
      RutaTono.naranja => const ColoresDeTono(
        AppColors.orangeTile,
        AppColors.warning,
      ),
    };
  }
}
