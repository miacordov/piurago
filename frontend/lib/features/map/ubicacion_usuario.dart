import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../data/ubicacion/servicio_ubicacion.dart';

/// Recuerda, mientras la app está abierta (en memoria), si ya se pidió el
/// permiso de ubicación automáticamente. Así el cuadro de Chrome o el
/// diálogo de Android sale solo una vez por sesión, aunque se abra el mapa
/// varias veces.
class SesionUbicacion {
  bool permisoSolicitado = false;
}

/// Ubicación del usuario en los mapas (el de la ruta y el de Planificar
/// viaje).
///
/// Al abrir el mapa:
/// - concedido: sigue la posición y centra el mapa, sin pedir nada;
/// - pendiente o denegado: pide el permiso nativo una sola vez por sesión;
/// - denegado para siempre o GPS apagado: no pide; muestra el aviso.
///
/// El botón "Mi ubicación" vuelve a consultar el permiso cada vez (lo pide
/// si está denegado) y centra el mapa. Sin permiso la app sigue funcionando
/// con un aviso discreto con "Activar ubicación".
class UbicacionUsuario extends ChangeNotifier {
  UbicacionUsuario(
    this._servicio, {
    SesionUbicacion? sesion,
    this.distanceFilter = ServicioUbicacion.distanciaMinimaPorDefecto,
  }) : _sesion = sesion ?? SesionUbicacion();

  final ServicioUbicacion _servicio;
  final SesionUbicacion _sesion;

  /// Metros que debe moverse el usuario para actualizar el marcador.
  final int distanceFilter;

  EstadoPermisoUbicacion? _estado;
  PosicionUsuario? _posicion;
  LatLng? _centroPendiente;
  bool _mostrarAviso = false;
  bool _centrarAlLlegar = false;
  bool _descartado = false;
  StreamSubscription<PosicionUsuario>? _suscripcion;

  /// Último estado conocido del permiso (null si aún no se consultó o si el
  /// servicio no está disponible).
  EstadoPermisoUbicacion? get estado => _estado;

  /// Última posición recibida (null mientras no haya permiso o señal).
  PosicionUsuario? get posicion => _posicion;

  /// true si hay que mostrar el aviso "Activar ubicación".
  bool get mostrarAviso => _mostrarAviso;

  /// Devuelve el punto en el que el mapa debe centrarse y lo descarta. Se
  /// guarda hasta que el mapa lo toma: así no se pierde si la posición llega
  /// antes de que el mapa esté listo.
  LatLng? tomarCentro() {
    final centro = _centroPendiente;
    _centroPendiente = null;
    return centro;
  }

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

  /// Al abrir el mapa.
  Future<void> iniciar() async {
    var estado = await _consultar(_servicio.verificar);
    if (estado == EstadoPermisoUbicacion.denegado &&
        !_sesion.permisoSolicitado) {
      _sesion.permisoSolicitado = true;
      estado = await _consultar(_servicio.solicitar);
    }
    _aplicar(estado);
  }

  /// Botón "Mi ubicación": consulta el permiso de nuevo (por si se revocó o
  /// se concedió desde los ajustes), lo pide si está denegado y centra.
  Future<void> miUbicacion() async {
    _sesion.permisoSolicitado = true;
    _aplicar(await _consultar(_servicio.solicitar));
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

  void _aplicar(EstadoPermisoUbicacion? estado) {
    // null: el servicio falló; la app sigue sin ubicación y sin avisos.
    if (estado == null || _descartado) return;
    if (estado == EstadoPermisoUbicacion.concedido) {
      _mostrarAviso = false;
      final actual = _posicion;
      if (actual != null && _suscripcion != null) {
        _centroPendiente = actual.punto;
      } else {
        // Sin posición o con el stream terminado: se suscribe (otra vez) y
        // centra cuando llegue la primera posición.
        _centrarAlLlegar = true;
        _escuchar();
      }
    } else {
      // Sin permiso se deja de seguir la posición y se quita el marcador.
      _mostrarAviso = true;
      _suscripcion?.cancel();
      _suscripcion = null;
      _posicion = null;
      _centroPendiente = null;
      _centrarAlLlegar = false;
    }
    _notificar();
  }

  /// Consulta el servicio; si falla (sin plugin, sitio sin HTTPS), devuelve
  /// null.
  Future<EstadoPermisoUbicacion?> _consultar(
    Future<EstadoPermisoUbicacion> Function() consulta,
  ) async {
    try {
      final estado = await consulta();
      if (_descartado) return null;
      _estado = estado;
      return estado;
    } catch (_) {
      return null;
    }
  }

  void _escuchar() {
    if (_suscripcion != null || _descartado) return;
    _suscripcion = _servicio
        .posiciones(distanceFilter: distanceFilter)
        .listen(
          (posicion) {
            _posicion = posicion;
            if (_centrarAlLlegar) {
              _centrarAlLlegar = false;
              _centroPendiente = posicion.punto;
            }
            _notificar();
          },
          // Sin señal: el marcador se queda en la última posición conocida.
          onError: (Object _) {},
          // El stream terminó: el próximo "Mi ubicación" se vuelve a suscribir.
          onDone: () => _suscripcion = null,
        );
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _suscripcion?.cancel();
    super.dispose();
  }
}
