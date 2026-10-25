import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../data/models/ruta.dart';

/// Tarjeta de una línea en la lista de rutas.
class RutaCard extends StatelessWidget {
  const RutaCard({super.key, required this.ruta});

  final Ruta ruta;

  @override
  Widget build(BuildContext context) {
    final colores = ColoresDeTono.de(ruta.tono);
    final puntos = ruta.lugaresDestacados.isNotEmpty
        ? ruta.lugaresDestacados.take(3).toList()
        : [ruta.puntoInicio, ruta.puntoFinal].whereType<String>().toList();
    final subtitulo = [
      ruta.empresa,
      ruta.tipoServicio,
      if (ruta.pasaje != null) 'S/ ${ruta.pasaje!.toStringAsFixed(2)}',
    ].whereType<String>().join(' · ');
    // Sin ETA en vivo se muestra cada cuánto pasa la línea.
    final (etiqueta, valor) = !ruta.activa
        ? ('Estado', 'Fuera de servicio')
        : ruta.etaMinutos != null
        ? ('Próxima unidad', '${ruta.etaMinutos} min')
        : ruta.frecuenciaMinutos != null
        ? ('Frecuencia', 'cada ~${ruta.frecuenciaMinutos} min')
        : ('Próxima unidad', '—');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 38),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colores.fondo,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ruta.codigo == null
                    ? Icon(
                        Icons.directions_bus_outlined,
                        size: 20,
                        color: colores.icono,
                      )
                    : Text(
                        ruta.codigo!,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo.isNotEmpty ? subtitulo : ruta.descripcion ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final punto in puntos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      punto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      valor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ruta.activa
                            ? AppColors.primary
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(AppRoutes.mapa, arguments: ruta.idRuta),
                style: appCompactButtonStyle(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver en mapa'),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
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
