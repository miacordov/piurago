import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../routes/ruta_card.dart';
import 'busqueda_viaje.dart';

/// "Sube en Mercado Modelo · 120 m a pie (2 min)".
String textoSubida(OpcionViaje o) =>
    'Sube en ${o.sube.nombre} · ${o.metrosSubida.round()} m a pie '
    '(${o.minutosSubida} min)';

/// "Baja en Real Plaza · 80 m a pie (1 min)".
String textoBajada(OpcionViaje o) =>
    'Baja en ${o.baja.nombre} · ${o.metrosBajada.round()} m a pie '
    '(${o.minutosBajada} min)';

/// "Pasa cada ~10 min", si se conoce la frecuencia.
String? textoFrecuencia(OpcionViaje o) => o.frecuenciaMinutos == null
    ? null
    : 'Pasa cada ~${o.frecuenciaMinutos} min';

/// Tarjeta de una línea que sirve para el viaje, como en Moovit: arriba la
/// duración aproximada y el pasaje, luego el recorrido en una tira
/// (a pie › línea › a pie) y dónde subir y bajar. Un clic la elige (se
/// dibuja en el mapa); la elegida se resalta y muestra "Iniciar viaje".
class OpcionViajeCard extends StatelessWidget {
  const OpcionViajeCard({
    super.key,
    required this.opcion,
    this.elegida = false,
    this.onTap,
    this.onIniciarViaje,
  });

  final OpcionViaje opcion;
  final bool elegida;
  final VoidCallback? onTap;
  final VoidCallback? onIniciarViaje;

  @override
  Widget build(BuildContext context) {
    final ruta = opcion.ruta;
    final detalle = [
      opcion.empresa,
      opcion.tipoServicio,
    ].whereType<String>().join(' · ');
    final frecuencia = textoFrecuencia(opcion);
    final pasaje = opcion.pasaje;
    return Material(
      color: elegida ? AppColors.background : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: elegida
            ? const BorderSide(color: AppColors.primary, width: 2)
            : const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '≈ ${opcion.minutosTotales} min',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const TextSpan(
                            text: '  aprox.',
                            style: AppText.small,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pasaje != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'S/ ${pasaje.toStringAsFixed(2)}',
                      style: AppText.label,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _Itinerario(opcion: opcion),
              const SizedBox(height: 10),
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
              const SizedBox(height: 8),
              _FilaTramo(
                icono: Icons.directions_walk,
                texto: textoSubida(opcion),
              ),
              const SizedBox(height: 4),
              _FilaTramo(
                icono: Icons.flag_outlined,
                texto: textoBajada(opcion),
              ),
              if (frecuencia != null) ...[
                const SizedBox(height: 8),
                Text(
                  frecuencia,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small,
                ),
              ],
              if (elegida && onIniciarViaje != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onIniciarViaje,
                  style: appFilledButtonStyle(),
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Iniciar viaje'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tira del recorrido: minutos a pie › línea (con su color) › minutos a pie.
class _Itinerario extends StatelessWidget {
  const _Itinerario({required this.opcion});

  final OpcionViaje opcion;

  @override
  Widget build(BuildContext context) {
    final colores = ColoresDeTono.de(opcion.ruta.tono);
    const flecha = Icon(
      Icons.chevron_right,
      size: 18,
      color: AppColors.textMuted,
    );
    return Semantics(
      label:
          '${opcion.minutosSubida} minutos a pie, línea '
          '${opcion.ruta.codigo ?? opcion.ruta.nombre}, '
          '${opcion.minutosBajada} minutos a pie',
      child: ExcludeSemantics(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          runSpacing: 4,
          children: [
            _APie(minutos: opcion.minutosSubida),
            flecha,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colores.fondo,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bus, size: 15, color: colores.icono),
                  const SizedBox(width: 4),
                  Text(
                    opcion.ruta.codigo ?? '—',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colores.icono,
                    ),
                  ),
                ],
              ),
            ),
            flecha,
            _APie(minutos: opcion.minutosBajada),
          ],
        ),
      ),
    );
  }
}

class _APie extends StatelessWidget {
  const _APie({required this.minutos});

  final int minutos;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.directions_walk, size: 16, color: AppColors.textMuted),
        Text('$minutos', style: AppText.small),
      ],
    );
  }
}

class _FilaTramo extends StatelessWidget {
  const _FilaTramo({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}
