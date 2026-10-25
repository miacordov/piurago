import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/paradero.dart';

/// Mapa de OpenStreetMap con el recorrido y los paraderos de una ruta.
///
/// Usa las teselas públicas de OpenStreetMap, que tienen una política de uso:
/// hay que identificar la aplicación (`userAgentPackageName`), mostrar la
/// atribución y no abusar del servicio. Ver docs/diseno/mapa-osm.md.
class RutaMap extends StatefulWidget {
  const RutaMap({
    super.key,
    required this.paraderos,
    this.esDemostracion = false,
  });

  final List<Paradero> paraderos;

  /// Si es true, avisa que el recorrido es ilustrativo.
  final bool esDemostracion;

  static const urlTeselas = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const identificadorApp = 'com.piurago.piurago';

  /// Plaza de Armas de Piura (aproximada): centro del mapa cuando no hay ruta.
  static const centroPiura = LatLng(-5.1945, -80.6328);

  @override
  State<RutaMap> createState() => _RutaMapState();
}

class _RutaMapState extends State<RutaMap> {
  final _controller = MapController();

  List<LatLng> get _puntos =>
      widget.paraderos.map((p) => LatLng(p.latitud, p.longitud)).toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Encuadre que muestra toda la ruta, o null si hay menos de dos puntos.
  CameraFit? _encuadre() {
    final puntos = _puntos;
    if (puntos.length < 2) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(puntos),
      padding: const EdgeInsets.all(72),
    );
  }

  void _zoom(double cambio) {
    final camara = _controller.camera;
    final nuevo = (camara.zoom + cambio).clamp(5.0, 19.0).toDouble();
    _controller.move(camara.center, nuevo);
  }

  void _centrarRuta() {
    final encuadre = _encuadre();
    if (encuadre != null) {
      _controller.fitCamera(encuadre);
    } else {
      _controller.move(RutaMap.centroPiura, 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _puntos;
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: RutaMap.centroPiura,
            initialZoom: 14,
            initialCameraFit: _encuadre(),
            minZoom: 5,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: RutaMap.urlTeselas,
              userAgentPackageName: RutaMap.identificadorApp,
            ),
            if (puntos.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: puntos,
                    strokeWidth: 14,
                    color: Colors.white,
                  ),
                  Polyline(
                    points: puntos,
                    strokeWidth: 6,
                    color: AppColors.primary,
                    pattern: StrokePattern.dashed(segments: const [16, 10]),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final (i, p) in widget.paraderos.indexed)
                  Marker(
                    point: LatLng(p.latitud, p.longitud),
                    width: 32,
                    height: 32,
                    child: _MarcadorParadero(
                      numero: i + 1,
                      nombre: p.nombre,
                      primero: i == 0,
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (widget.esDemostracion)
          const Positioned(left: 12, top: 12, child: _NotaDemostracion()),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BotonMapa(
                icono: Icons.add,
                ayuda: 'Acercar',
                onPressed: () => _zoom(1),
              ),
              const SizedBox(height: 8),
              _BotonMapa(
                icono: Icons.remove,
                ayuda: 'Alejar',
                onPressed: () => _zoom(-1),
              ),
              const SizedBox(height: 8),
              _BotonMapa(
                icono: Icons.my_location,
                ayuda: 'Centrar la ruta',
                onPressed: _centrarRuta,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarcadorParadero extends StatelessWidget {
  const _MarcadorParadero({
    required this.numero,
    required this.nombre,
    required this.primero,
  });

  final int numero;
  final String nombre;
  final bool primero;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: nombre,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primero ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        child: Text(
          '$numero',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primero ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _BotonMapa extends StatelessWidget {
  const _BotonMapa({
    required this.icono,
    required this.ayuda,
    required this.onPressed,
  });

  final IconData icono;
  final String ayuda;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: ayuda,
      child: Material(
        color: AppColors.surface,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icono, size: 20, color: AppColors.text),
          ),
        ),
      ),
    );
  }
}

class _NotaDemostracion extends StatelessWidget {
  const _NotaDemostracion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: AppColors.success),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Recorrido ilustrativo · ETA de demostración',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
