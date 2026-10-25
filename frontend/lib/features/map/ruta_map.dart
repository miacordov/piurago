import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/paradero.dart';
import '../viaje/busqueda_viaje.dart';

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
    this.paraderosDestacados,
    this.marcadoresExtra = const [],
    this.lineasExtra = const [],
    this.encuadre,
    this.alTocar,
  });

  /// Paraderos de la ruta: con dos o más se dibuja el recorrido.
  final List<Paradero> paraderos;

  /// Si es true, avisa que el recorrido es ilustrativo.
  final bool esDemostracion;

  /// Si se indica, solo se marcan estos paraderos (sin número) en lugar de
  /// todos los de la ruta.
  final List<Paradero>? paraderosDestacados;

  /// Marcadores y líneas adicionales (por ejemplo, origen, destino y
  /// caminatas de Planificar viaje).
  final List<Marker> marcadoresExtra;
  final List<Polyline> lineasExtra;

  /// Puntos que el mapa debe mostrar. Si cambian, el mapa se reencuadra. Si
  /// no se indica, se encuadran los paraderos.
  final List<LatLng>? encuadre;

  /// Se llama con la coordenada tocada en el mapa.
  final ValueChanged<LatLng>? alTocar;

  /// Zoom al centrar un solo punto (o varios casi iguales).
  static const zoomPuntoUnico = 15.0;

  static const urlTeselas = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const identificadorApp = 'com.piurago.piurago';

  /// Plaza de Armas de Piura (aproximada): centro del mapa cuando no hay ruta.
  static const centroPiura = LatLng(-5.1945, -80.6328);

  @override
  State<RutaMap> createState() => _RutaMapState();
}

class _RutaMapState extends State<RutaMap> {
  final _controller = MapController();
  bool _listo = false;

  List<LatLng> get _puntos => widget.paraderos.map(posicionDe).toList();

  List<LatLng> get _puntosEncuadre => widget.encuadre ?? _puntos;

  @override
  void didUpdateWidget(RutaMap anterior) {
    super.didUpdateWidget(anterior);
    if (!listEquals(anterior.encuadre, widget.encuadre)) {
      // El controlador se usa después del frame, cuando el mapa ya se dibujó.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _listo) _encuadrar();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Encuadre con margen para dos o más puntos distintos. Con uno solo (o
  /// varios casi iguales) se centra con zoom fijo, porque el encuadre
  /// acercaría el mapa al máximo.
  CameraFit? _encuadre() {
    final puntos = _puntosEncuadre;
    if (puntos.length < 2 || puntosCasiIguales(puntos)) return null;
    return CameraFit.coordinates(
      coordinates: puntos,
      padding: const EdgeInsets.all(72),
    );
  }

  void _encuadrar() {
    final puntos = _puntosEncuadre;
    final encuadre = _encuadre();
    if (encuadre != null) {
      _controller.fitCamera(encuadre);
    } else if (puntos.isNotEmpty) {
      _controller.move(puntos.first, RutaMap.zoomPuntoUnico);
    } else {
      _controller.move(RutaMap.centroPiura, 14);
    }
  }

  void _zoom(double cambio) {
    final camara = _controller.camera;
    final nuevo = (camara.zoom + cambio).clamp(5.0, 19.0).toDouble();
    _controller.move(camara.center, nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _puntos;
    final iniciales = _puntosEncuadre;
    final destacados = widget.paraderosDestacados;
    final marcados = destacados ?? widget.paraderos;
    final alTocar = widget.alTocar;
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: iniciales.isEmpty
                ? RutaMap.centroPiura
                : iniciales.first,
            initialZoom: iniciales.isEmpty ? 14 : RutaMap.zoomPuntoUnico,
            initialCameraFit: _encuadre(),
            onMapReady: () => _listo = true,
            onTap: alTocar == null ? null : (_, punto) => alTocar(punto),
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
            if (widget.lineasExtra.isNotEmpty)
              PolylineLayer(polylines: widget.lineasExtra),
            MarkerLayer(
              markers: [
                for (final (i, p) in marcados.indexed)
                  Marker(
                    point: posicionDe(p),
                    width: 32,
                    height: 32,
                    child: _MarcadorParadero(
                      numero: destacados == null ? i + 1 : null,
                      nombre: p.nombre,
                      primero: destacados != null || i == 0,
                    ),
                  ),
                ...widget.marcadoresExtra,
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
                icono: Icons.fit_screen,
                ayuda: 'Centrar el mapa',
                onPressed: _encuadrar,
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

  /// Número del paradero en la ruta; sin número se muestra un bus.
  final int? numero;
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
        child: numero == null
            ? Icon(
                Icons.directions_bus,
                size: 16,
                color: primero ? Colors.white : AppColors.primary,
              )
            : Text(
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
