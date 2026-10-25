import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../map/ruta_map.dart';
import 'busqueda_viaje.dart';
import 'planificador_viaje.dart';

/// Mapa de Planificar viaje. Sin resultado elegido no dibuja ninguna línea:
/// solo el origen y el destino. Con un resultado elegido dibuja esa ruta, el
/// paradero donde se sube y el de bajada, y las caminatas punteadas.
class MapaViaje extends StatelessWidget {
  const MapaViaje({
    super.key,
    required this.planificador,
    this.esDemostracion = false,
  });

  final PlanificadorViaje planificador;
  final bool esDemostracion;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: planificador,
      builder: (context, _) {
        final origen = planificador.origen?.posicion;
        final destino = planificador.destino?.posicion;
        final elegida = planificador.elegida;
        final sube = elegida == null ? null : posicionDe(elegida.sube);
        final baja = elegida == null ? null : posicionDe(elegida.baja);
        return RutaMap(
          paraderos: elegida == null
              ? const []
              : planificador.paraderosDe(elegida.ruta.idRuta),
          trazado: elegida == null
              ? const []
              : planificador.trazadoDe(elegida.ruta.idRuta),
          paraderosDestacados: elegida == null
              ? const []
              : [elegida.sube, elegida.baja],
          esDemostracion: esDemostracion,
          alTocar: planificador.fijarPunto,
          encuadre: [?origen, ?sube, ?baja, ?destino],
          lineasExtra: [
            if (origen != null && sube != null) _caminata(origen, sube),
            if (baja != null && destino != null) _caminata(baja, destino),
          ],
          marcadoresExtra: [
            if (origen != null)
              _marcador(
                origen,
                'Desde: ${planificador.origen!.nombre}',
                Icons.trip_origin,
                AppColors.success,
              ),
            if (destino != null)
              _marcador(
                destino,
                'Hasta: ${planificador.destino!.nombre}',
                Icons.place,
                AppColors.danger,
              ),
          ],
        );
      },
    );
  }

  static Polyline _caminata(LatLng desde, LatLng hasta) {
    return Polyline(
      points: [desde, hasta],
      strokeWidth: 4,
      color: AppColors.textMuted,
      pattern: const StrokePattern.dotted(),
    );
  }

  static Marker _marcador(
    LatLng punto,
    String ayuda,
    IconData icono,
    Color color,
  ) {
    return Marker(
      point: punto,
      width: 36,
      height: 36,
      child: Tooltip(
        message: ayuda,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(icono, size: 18, color: color),
        ),
      ),
    );
  }
}
