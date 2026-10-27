import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Resultado del pedido de permisos de ubicación.
enum EstadoPermisoUbicacion {
  concedido,
  denegado,
  denegadoParaSiempre,
  servicioDesactivado,
}

/// Contrato para el servicio de geolocalización (DIP de SOLID).
/// Permite desacoplar el hardware de la interfaz y simular la ubicación
/// en tests unitarios y CI sin requerir un chip GPS real.
abstract class ServicioUbicacion {
  Future<bool> estaServicioHabilitado();
  Future<EstadoPermisoUbicacion> verificarPermiso();
  Future<EstadoPermisoUbicacion> solicitarPermiso();
  Future<LatLng?> obtenerPosicionActual();
  Stream<LatLng> escucharPosicion();
}

/// Implementación real usando el plugin geolocator de Flutter.
class GeolocatorServicioUbicacion implements ServicioUbicacion {
  const GeolocatorServicioUbicacion();

  @override
  Future<bool> estaServicioHabilitado() async {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<EstadoPermisoUbicacion> verificarPermiso() async {
    final permiso = await Geolocator.checkPermission();
    return _convertirPermiso(permiso);
  }

  @override
  Future<EstadoPermisoUbicacion> solicitarPermiso() async {
    final habilitado = await Geolocator.isLocationServiceEnabled();
    if (!habilitado) {
      return EstadoPermisoUbicacion.servicioDesactivado;
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return _convertirPermiso(permiso);
  }

  @override
  Future<LatLng?> obtenerPosicionActual() async {
    try {
      final estado = await solicitarPermiso();
      if (estado != EstadoPermisoUbicacion.concedido) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LatLng> escucharPosicion() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  EstadoPermisoUbicacion _convertirPermiso(LocationPermission permiso) {
    return switch (permiso) {
      LocationPermission.always || LocationPermission.whileInUse =>
        EstadoPermisoUbicacion.concedido,
      LocationPermission.deniedForever =>
        EstadoPermisoUbicacion.denegadoParaSiempre,
      LocationPermission.denied || LocationPermission.unableToDetermine =>
        EstadoPermisoUbicacion.denegado,
    };
  }
}

/// Implementación para pruebas unitarias y entornos sin GPS.
class FakeServicioUbicacion implements ServicioUbicacion {
  FakeServicioUbicacion({
    this.permisoInicial = EstadoPermisoUbicacion.denegado,
    this.posicionFija = const LatLng(-5.1944, -80.6328),
  }) : _estadoPermiso = permisoInicial;

  final EstadoPermisoUbicacion permisoInicial;
  final LatLng? posicionFija;
  EstadoPermisoUbicacion _estadoPermiso;
  int vecesSolicitado = 0;

  @override
  Future<bool> estaServicioHabilitado() async => true;

  @override
  Future<EstadoPermisoUbicacion> verificarPermiso() async => _estadoPermiso;

  @override
  Future<EstadoPermisoUbicacion> solicitarPermiso() async {
    vecesSolicitado++;
    _estadoPermiso = EstadoPermisoUbicacion.concedido;
    return _estadoPermiso;
  }

  @override
  Future<LatLng?> obtenerPosicionActual() async {
    if (_estadoPermiso == EstadoPermisoUbicacion.concedido) {
      return posicionFija;
    }
    return null;
  }

  @override
  Stream<LatLng> escucharPosicion() {
    if (posicionFija != null) {
      return Stream.value(posicionFija!);
    }
    return const Stream.empty();
  }
}
