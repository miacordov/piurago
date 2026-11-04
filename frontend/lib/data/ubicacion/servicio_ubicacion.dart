import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Estado del permiso de ubicación (y del GPS del equipo).
enum EstadoPermisoUbicacion {
  concedido,
  denegado,
  denegadoParaSiempre,
  servicioDesactivado,
}

/// Posición del usuario con su precisión en metros (radio del círculo que se
/// dibuja alrededor del marcador).
@immutable
class PosicionUsuario {
  const PosicionUsuario(this.punto, this.precisionMetros);

  final LatLng punto;
  final double precisionMetros;
}

/// Contrato para el servicio de geolocalización (DIP de SOLID).
/// Desacopla el hardware de la interfaz: en las pruebas se inyecta
/// [FakeServicioUbicacion] en lugar del GPS real.
abstract class ServicioUbicacion {
  const ServicioUbicacion();

  /// Metros que debe moverse el usuario para que el stream emita otra
  /// posición.
  static const distanciaMinimaPorDefecto = 10;

  /// true en el navegador: ahí no hay "ajustes de la app" y el permiso
  /// denegado se vuelve a activar desde el candado de la barra de direcciones.
  bool get esWeb;

  /// Estado actual, sin mostrar ningún diálogo.
  Future<EstadoPermisoUbicacion> verificar();

  /// Muestra el permiso nativo (cuadro de Chrome o diálogo de Android) si
  /// todavía falta, y devuelve el estado resultante.
  Future<EstadoPermisoUbicacion> solicitar();

  /// Posiciones del usuario; solo emite tras moverse [distanceFilter] metros.
  Stream<PosicionUsuario> posiciones({
    int distanceFilter = distanciaMinimaPorDefecto,
  });

  /// Solo las coordenadas (lo usa el viaje en vivo para el GPS colaborativo).
  Stream<LatLng> escucharPosicion() => posiciones().map((p) => p.punto);

  /// Ajustes de la app en el sistema (permiso denegado para siempre).
  Future<bool> abrirAjustesApp();

  /// Ajustes de ubicación del sistema (GPS apagado).
  Future<bool> abrirAjustesUbicacion();
}

/// Implementación real con el plugin geolocator.
class GeolocatorServicioUbicacion extends ServicioUbicacion {
  const GeolocatorServicioUbicacion({this.esWeb = kIsWeb});

  @override
  final bool esWeb;

  @override
  Future<EstadoPermisoUbicacion> verificar() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return EstadoPermisoUbicacion.servicioDesactivado;
    }
    return _convertir(await Geolocator.checkPermission());
  }

  @override
  Future<EstadoPermisoUbicacion> solicitar() async {
    final estado = await verificar();
    if (estado != EstadoPermisoUbicacion.denegado) return estado;
    return _convertir(await Geolocator.requestPermission());
  }

  @override
  Stream<PosicionUsuario> posiciones({
    int distanceFilter = ServicioUbicacion.distanciaMinimaPorDefecto,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).map(
      (pos) =>
          PosicionUsuario(LatLng(pos.latitude, pos.longitude), pos.accuracy),
    );
  }

  @override
  Future<bool> abrirAjustesApp() => Geolocator.openAppSettings();

  @override
  Future<bool> abrirAjustesUbicacion() => Geolocator.openLocationSettings();

  static EstadoPermisoUbicacion _convertir(LocationPermission permiso) {
    return switch (permiso) {
      LocationPermission.always ||
      LocationPermission.whileInUse => EstadoPermisoUbicacion.concedido,
      LocationPermission.deniedForever =>
        EstadoPermisoUbicacion.denegadoParaSiempre,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => EstadoPermisoUbicacion.denegado,
    };
  }
}

/// Implementación para pruebas y entornos sin GPS: el estado y la respuesta
/// al diálogo se configuran, y las posiciones se emiten con [emitir].
class FakeServicioUbicacion extends ServicioUbicacion {
  FakeServicioUbicacion({
    EstadoPermisoUbicacion estadoInicial = EstadoPermisoUbicacion.denegado,
    this.respuestaSolicitud = EstadoPermisoUbicacion.concedido,
    this.esWeb = false,
  }) : _estado = estadoInicial;

  /// Estado que deja solicitar() (lo que "responde" la persona al diálogo).
  EstadoPermisoUbicacion respuestaSolicitud;

  @override
  final bool esWeb;

  EstadoPermisoUbicacion _estado;
  final _posiciones = StreamController<PosicionUsuario>.broadcast();

  int vecesSolicitado = 0;
  int vecesAjustesApp = 0;
  int vecesAjustesUbicacion = 0;
  int? ultimoDistanceFilter;

  /// Envía una posición a quienes escuchan el stream.
  void emitir(PosicionUsuario posicion) => _posiciones.add(posicion);

  @override
  Future<EstadoPermisoUbicacion> verificar() async => _estado;

  @override
  Future<EstadoPermisoUbicacion> solicitar() async {
    vecesSolicitado++;
    if (_estado != EstadoPermisoUbicacion.concedido) {
      _estado = respuestaSolicitud;
    }
    return _estado;
  }

  @override
  Stream<PosicionUsuario> posiciones({
    int distanceFilter = ServicioUbicacion.distanciaMinimaPorDefecto,
  }) {
    ultimoDistanceFilter = distanceFilter;
    return _posiciones.stream;
  }

  @override
  Future<bool> abrirAjustesApp() async {
    vecesAjustesApp++;
    return true;
  }

  @override
  Future<bool> abrirAjustesUbicacion() async {
    vecesAjustesUbicacion++;
    return true;
  }
}
