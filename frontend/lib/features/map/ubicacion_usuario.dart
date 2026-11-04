import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../data/ubicacion/servicio_ubicacion.dart';

/// Ubicación del usuario en los mapas (el de la ruta y el de Planificar
/// viaje). El permiso lo pide el sistema (cuadro de Chrome o diálogo de
/// Android) al tocar "Mi ubicación". Si se deniega, la app sigue
/// funcionando y se muestra un aviso discreto con "Activar ubicación".
class UbicacionUsuario extends ChangeNotifier {
  UbicacionUsuario(
    this._servicio, {
    this.distanceFilter = ServicioUbicacion.distanciaMinimaPorDefecto,
  });

  final ServicioUbicacion _servicio;

  /// Metros que debe moverse el usuario para actualizar el marcador.
  final int distanceFilter;

  EstadoPermisoUbicacion? _estado;
  PosicionUsuario? _posicion;
  bool _mostrarAviso = false;
  bool _centrarAlLlegar = false;
  bool _descartado = false;
  StreamSubscription<PosicionUsuario>? _suscripcion;
  final _centrados = StreamController<LatLng>.broadcast();

  /// Último estado conocido del permiso (null si aún no se consultó o si el
  /// servicio no está disponible).
  EstadoPermisoUbicacion? get estado => _estado;

  /// Última posición recibida (null mientras no haya permiso o señal).
  PosicionUsuario? get posicion => _posicion;

  /// true si hay que mostrar el aviso "Activar ubicación".
  bool get mostrarAviso => _mostrarAviso;

  /// Puntos en los que el mapa debe centrarse.
  Stream<LatLng> get centrados => _centrados.stream;

  /// En web, el permiso bloqueado se vuelve a dar desde el navegador: no hay
  /// botón que lo resuelva.
  bool get puedeActivar =>
      !(_servicio.esWeb &&
          _estado == EstadoPermisoUbicacion.denegadoParaSiempre);

  String get mensajeAviso => switch (_estado) {
    EstadoPermisoUbicacion.servicioDesactivado =>
      'El GPS de tu equipo está apagado.',
    EstadoPermisoUbicacion.denegadoParaSiempre when _servicio.esWeb =>
      'Para ver dónde estás, permite la ubicación desde el candado de la '
          'barra de direcciones.',
    EstadoPermisoUbicacion.denegadoParaSiempre =>
      'El permiso de ubicación está bloqueado en los ajustes.',
    _ => 'Sin tu ubicación igual puedes ver las rutas.',
  };

  /// Al abrir el mapa: consulta el permiso sin mostrar diálogos y, si ya
  /// está concedido, empieza a seguir la posición.
  Future<void> iniciar() async {
    final estado = await _consultar(_servicio.verificar);
    if (estado == EstadoPermisoUbicacion.concedido) _escuchar();
  }

  /// Botón "Mi ubicación": pide el permiso si falta y centra el mapa.
  Future<void> miUbicacion() async {
    final actual = _posicion;
    if (_estado == EstadoPermisoUbicacion.concedido && actual != null) {
      _centrar(actual.punto);
      return;
    }
    final estado = await _consultar(_servicio.solicitar);
    if (estado == null) return;
    if (estado == EstadoPermisoUbicacion.concedido) {
      _mostrarAviso = false;
      _centrarAlLlegar = true;
      _escuchar();
    } else {
      _mostrarAviso = true;
    }
    _notificar();
  }

  /// Botón "Activar ubicación" del aviso.
  Future<void> activar() async {
    try {
      switch (_estado) {
        case EstadoPermisoUbicacion.servicioDesactivado:
          await _servicio.abrirAjustesUbicacion();
        case EstadoPermisoUbicacion.denegadoParaSiempre:
          if (!_servicio.esWeb) await _servicio.abrirAjustesApp();
        case EstadoPermisoUbicacion.denegado || null:
          await miUbicacion();
        case EstadoPermisoUbicacion.concedido:
          break;
      }
    } catch (_) {
      // Sin ajustes que abrir: el aviso queda como está.
    }
  }

  void cerrarAviso() {
    _mostrarAviso = false;
    _notificar();
  }

  /// Consulta el servicio; si falla (sin plugin, sitio sin HTTPS), la app
  /// sigue sin ubicación y sin avisos.
  Future<EstadoPermisoUbicacion?> _consultar(
    Future<EstadoPermisoUbicacion> Function() consulta,
  ) async {
    try {
      final estado = await consulta();
      if (_descartado) return null;
      _estado = estado;
      _notificar();
      return estado;
    } catch (_) {
      return null;
    }
  }

  void _escuchar() {
    if (_suscripcion != null || _descartado) return;
    _suscripcion = _servicio.posiciones(distanceFilter: distanceFilter).listen(
      (posicion) {
        _posicion = posicion;
        if (_centrarAlLlegar) {
          _centrarAlLlegar = false;
          _centrar(posicion.punto);
        }
        _notificar();
      },
      // Sin señal: el marcador se queda en la última posición conocida.
      onError: (Object _) {},
    );
  }

  void _centrar(LatLng punto) {
    if (!_descartado) _centrados.add(punto);
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _suscripcion?.cancel();
    _centrados.close();
    super.dispose();
  }
}
