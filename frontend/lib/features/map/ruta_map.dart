import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/paradero.dart';
import '../viaje/busqueda_viaje.dart';
import 'ubicacion_usuario.dart';

/// Mapa de OpenStreetMap con el recorrido y los paraderos de una ruta.
///
/// Usa las teselas públicas de OpenStreetMap, que tienen una política de uso:
/// hay que identificar la aplicación (`userAgentPackageName`), mostrar la
/// atribución y no abusar del servicio. Ver docs/diseno/mapa-osm.md.
class RutaMap extends StatefulWidget {
  const RutaMap({
    super.key,
    required this.paraderos,
    this.trazado = const [],
    this.esDemostracion = false,
    this.paraderosDestacados,
    this.marcadoresExtra = const [],
    this.lineasExtra = const [],
    this.encuadre,
    this.alTocar,
    this.mostrarTeselas = true,
    this.ubicacion,
  });

  /// false en las pruebas, que no tienen internet: el mapa se dibuja sin las
  /// teselas de OpenStreetMap.
  final bool mostrarTeselas;

  /// Si se indica, muestra el botón "Mi ubicación", el marcador azul con su
  /// círculo de precisión y el aviso cuando falta el permiso.
  final UbicacionUsuario? ubicacion;

  /// Paraderos de la ruta: con dos o más se dibuja el recorrido.
  final List<Paradero> paraderos;

  /// Recorrido por las calles. Si está vacío, la línea une los paraderos en
  /// línea recta.
  final List<LatLng> trazado;

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

  /// Zoom mínimo al centrar en la ubicación del usuario.
  static const zoomMiUbicacion = 16.0;

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

  /// Puntos de la línea de la ruta: el trazado por las calles o, si no hay,
  /// los paraderos.
  List<LatLng> get _puntos => widget.trazado.length >= 2
      ? widget.trazado
      : widget.paraderos.map(posicionDe).toList();

  List<LatLng> get _puntosEncuadre => widget.encuadre ?? _puntos;

  @override
  void initState() {
    super.initState();
    widget.ubicacion?.addListener(_centrarEnUbicacion);
  }

  void _alEstarListo() {
    _listo = true;
    // Después del frame, para no quedar debajo del encuadre inicial de la
    // ruta.
    WidgetsBinding.instance.addPostFrameCallback((_) => _centrarEnUbicacion());
  }

  /// Centra el mapa en la posición del usuario si la ubicación lo pidió. El
  /// pedido queda guardado hasta que el mapa está listo.
  void _centrarEnUbicacion() {
    if (!_listo || !mounted) return;
    final punto = widget.ubicacion?.tomarCentro();
    if (punto == null) return;
    final zoom = math.max(_controller.camera.zoom, RutaMap.zoomMiUbicacion);
    _controller.move(punto, zoom);
  }

  @override
  void didUpdateWidget(RutaMap anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.ubicacion != widget.ubicacion) {
      anterior.ubicacion?.removeListener(_centrarEnUbicacion);
      widget.ubicacion?.addListener(_centrarEnUbicacion);
    }
    if (!listEquals(anterior.encuadre, widget.encuadre)) {
      // El controlador se usa después del frame, cuando el mapa ya se dibujó.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _listo) _encuadrar();
      });
    }
  }

  @override
  void dispose() {
    widget.ubicacion?.removeListener(_centrarEnUbicacion);
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
            onMapReady: _alEstarListo,
            onTap: alTocar == null ? null : (_, punto) => alTocar(punto),
            minZoom: 5,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            if (widget.mostrarTeselas)
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
            if (widget.ubicacion case final ubicacion?)
              _CapaMiUbicacion(ubicacion: ubicacion),
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
        if (widget.ubicacion case final ubicacion?) ...[
          Positioned(
            right: 16,
            top: 16,
            child: _BotonMiUbicacion(ubicacion: ubicacion),
          ),
          Positioned(
            left: 12,
            right: 72,
            top: widget.esDemostracion ? 56 : 12,
            child: _AvisoUbicacion(ubicacion: ubicacion),
          ),
        ],
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

/// Marcador azul de la posición del usuario con el círculo de su precisión
/// (en metros, así que crece o se achica con el zoom).
class _CapaMiUbicacion extends StatelessWidget {
  const _CapaMiUbicacion({required this.ubicacion});

  final UbicacionUsuario ubicacion;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ubicacion,
      builder: (context, _) {
        final posicion = ubicacion.posicion;
        if (posicion == null) return const SizedBox.shrink();
        return Stack(
          children: [
            CircleLayer(
              circles: [
                CircleMarker(
                  point: posicion.punto,
                  radius: posicion.precisionMetros,
                  useRadiusInMeter: true,
                  color: AppColors.ubicacion.withValues(alpha: 0.15),
                  borderColor: AppColors.ubicacion.withValues(alpha: 0.4),
                  borderStrokeWidth: 1,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: posicion.punto,
                  width: 22,
                  height: 22,
                  child: Tooltip(
                    key: const ValueKey('marcador-mi-ubicacion'),
                    message: 'Estás aquí',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.ubicacion,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BotonMiUbicacion extends StatelessWidget {
  const _BotonMiUbicacion({required this.ubicacion});

  final UbicacionUsuario ubicacion;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ubicacion,
      builder: (context, _) {
        final activa = ubicacion.posicion != null;
        return FloatingActionButton.small(
          heroTag: null,
          tooltip: 'Mi ubicación',
          backgroundColor: AppColors.surface,
          foregroundColor: activa ? AppColors.ubicacion : AppColors.text,
          onPressed: ubicacion.miUbicacion,
          child: Icon(activa ? Icons.my_location : Icons.location_searching),
        );
      },
    );
  }
}

/// Aviso discreto cuando no hay permiso de ubicación (o el GPS está
/// apagado). La app sigue funcionando sin la ubicación.
class _AvisoUbicacion extends StatelessWidget {
  const _AvisoUbicacion({required this.ubicacion});

  final UbicacionUsuario ubicacion;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ubicacion,
      builder: (context, _) {
        if (!ubicacion.mostrarAviso) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              // El texto arriba y "Activar ubicación" debajo, para que quepa
              // también en el celular.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.location_off_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ubicacion.mensajeAviso,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (ubicacion.puedeActivar)
                            TextButton(
                              onPressed: ubicacion.activar,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Activar ubicación'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar aviso',
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    onPressed: ubicacion.cerrarAviso,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
