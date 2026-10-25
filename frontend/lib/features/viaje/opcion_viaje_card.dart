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

/// "S/ 1.50 · cada ~10 min", con los datos que existan.
String textoServicio(OpcionViaje o) => [
  if (o.pasaje != null) 'S/ ${o.pasaje!.toStringAsFixed(2)}',
  if (o.frecuenciaMinutos != null) 'cada ~${o.frecuenciaMinutos} min',
].join(' · ');

/// Tarjeta de una línea que sirve para el viaje. Un clic la elige (se
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
    final colores = ColoresDeTono.de(ruta.tono);
    final detalle = [
      opcion.empresa,
      opcion.tipoServicio,
    ].whereType<String>().join(' · ');
    final servicio = textoServicio(opcion);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
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
                  Container(
                    constraints: const BoxConstraints(minWidth: 38),
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colores.fondo,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ruta.codigo ?? '—',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colores.icono,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FilaTramo(
                icono: Icons.directions_walk,
                texto: textoSubida(opcion),
              ),
              const SizedBox(height: 4),
              _FilaTramo(
                icono: Icons.flag_outlined,
                texto: textoBajada(opcion),
              ),
              if (servicio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  servicio,
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
