import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/paradero.dart';
import '../../data/models/ruta.dart';
import '../../data/rutas_repository.dart';
import 'busqueda_viaje.dart';

/// Campo del buscador que recibe el lugar elegido o el punto tocado en el mapa.
enum CampoViaje { desde, hasta }

/// Estados de la pantalla Planificar viaje.
enum EstadoViaje {
  /// Se están pidiendo las rutas y sus paraderos.
  cargando,

  /// Falta el origen o el destino.
  vacio,
  conResultados,

  /// Ninguna línea sirve, o el destino está tan cerca que conviene caminar
  /// (ver [PlanificadorViaje.muyCerca]).
  sinResultados,
  error,
}

/// Pasos de la guía de viaje. El pasajero avanza cada paso a mano: no se usa
/// el GPS ni se comparte la ubicación.
enum PasoViaje {
  caminarAlParadero,
  esperarBus,
  aBordo,
  caminarAlDestino,
  llegaste,
}

/// Estado del buscador "¿A dónde vas?". Pide las rutas y los paraderos de
/// todas ellas una sola vez (en paralelo) y los guarda en memoria. Primero se
/// pide el destino y luego el origen; con los dos, busca sola y elige la
/// mejor línea. Solo depende de la interfaz RutasRepository.
class PlanificadorViaje extends ChangeNotifier {
  PlanificadorViaje(this._repository, {this.lugaresConocidos = const []})
    : _calles = [
        for (final l in lugaresConocidos)
          if (l.tipo == TipoLugar.calle) l,
      ];

  /// Base propia de calles y lugares de Piura que se suma a los paraderos
  /// en las sugerencias (lib/data/lugares/lugares_piura.dart).
  final List<Lugar> lugaresConocidos;
  final List<Lugar> _calles;

  final RutasRepository _repository;

  List<Ruta> _rutas = const [];
  Map<int, List<Paradero>> _paraderos = const {};
  List<Lugar> _catalogo = const [];
  IndiceLugares _indice = IndiceLugares(const []);
  List<Lugar> _frecuentes = const [];
  bool _cargado = false;

  EstadoViaje _estado = EstadoViaje.cargando;
  Lugar? _origen;
  Lugar? _destino;
  CampoViaje _campoActivo = CampoViaje.hasta;
  List<OpcionViaje> _opciones = const [];
  bool _muyCerca = false;
  OpcionViaje? _elegida;
  PasoViaje? _paso;

  EstadoViaje get estado => _estado;
  Lugar? get origen => _origen;
  Lugar? get destino => _destino;
  CampoViaje get campoActivo => _campoActivo;
  List<Lugar> get catalogo => _catalogo;

  /// Lugares por los que pasan más líneas, para elegirlos con un clic.
  List<Lugar> get frecuentes => _frecuentes;
  List<OpcionViaje> get opciones => _opciones;
  bool get muyCerca => _muyCerca;
  OpcionViaje? get elegida => _elegida;

  /// Paso actual de la guía, o null si no hay un viaje iniciado.
  PasoViaje? get paso => _paso;

  /// Paraderos de una ruta ya cargados en memoria.
  List<Paradero> paraderosDe(int idRuta) =>
      _paraderos[idRuta] ?? const <Paradero>[];

  List<Lugar> sugerencias(String consulta) => _indice.sugerir(consulta);

  /// Pide las rutas y los paraderos de todas ellas. Si ya se cargaron, no
  /// vuelve a pedirlos.
  Future<void> cargar() async {
    if (_cargado) return;
    _estado = EstadoViaje.cargando;
    notifyListeners();
    try {
      final rutas = await _repository.listar();
      final listas = await Future.wait(
        rutas.map((r) => _repository.paraderos(r.idRuta)),
      );
      _rutas = rutas;
      _paraderos = {
        for (final (i, ruta) in rutas.indexed) ruta.idRuta: listas[i],
      };
      // Primero los paraderos (por ahí pasan las líneas) y luego la base de
      // Piura, sin repetir un nombre que ya es paradero. El índice de la
      // base se arma una sola vez y se reutiliza al volver al mapa.
      final paraderos = construirCatalogo(_rutas, _paraderos);
      final nombres = {for (final l in paraderos) normalizar(l.nombre)};
      _indice = IndiceLugares.unir(
        IndiceLugares(paraderos),
        IndiceLugares.de(lugaresConocidos),
        excluir: (l) => nombres.contains(normalizar(l.nombre)),
      );
      _catalogo = _indice.lugares;
      _frecuentes = lugaresFrecuentes(_rutas, _paraderos);
      _cargado = true;
      _estado = EstadoViaje.vacio;
    } catch (_) {
      _estado = EstadoViaje.error;
    }
    notifyListeners();
  }

  Future<void> reintentar() => cargar();

  void activarCampo(CampoViaje campo) {
    if (_campoActivo == campo) return;
    _campoActivo = campo;
    notifyListeners();
  }

  void fijarOrigen(Lugar? lugar) {
    _origen = lugar;
    _actualizar();
  }

  void fijarDestino(Lugar? lugar) {
    _destino = lugar;
    _actualizar();
  }

  /// Asigna un punto tocado en el mapa al campo activo.
  void fijarPunto(LatLng punto) {
    final lugar = _nombrarPunto(punto);
    if (_campoActivo == CampoViaje.hasta) {
      _destino = lugar;
    } else {
      _origen = lugar;
    }
    _actualizar();
  }

  /// Nombre de un punto tocado: la calle conocida más cercana (a menos de
  /// [distanciaNombreCalleMetros]) o "Punto en el mapa". No usa la red.
  Lugar _nombrarPunto(LatLng punto) {
    Lugar? cercana;
    var mejor = distanciaNombreCalleMetros;
    for (final calle in _calles) {
      final d = distanciaMetros(punto, calle.posicion);
      if (d < mejor) {
        mejor = d;
        cercana = calle;
      }
    }
    if (cercana == null) return Lugar(nombrePuntoEnMapa, punto);
    return Lugar(
      'Cerca de ${cercana.nombre}',
      punto,
      tipo: TipoLugar.calle,
      detalle: cercana.detalle,
    );
  }

  void intercambiar() {
    final origen = _origen;
    _origen = _destino;
    _destino = origen;
    _actualizar();
  }

  void limpiar() {
    _origen = null;
    _destino = null;
    _actualizar();
  }

  void elegir(OpcionViaje opcion) {
    _elegida = opcion;
    notifyListeners();
  }

  /// Empieza la guía con la línea elegida.
  void iniciarViaje() {
    if (_elegida == null) return;
    _paso = PasoViaje.caminarAlParadero;
    notifyListeners();
  }

  void avanzarPaso() {
    final paso = _paso;
    if (paso == null || paso == PasoViaje.llegaste) return;
    _paso = PasoViaje.values[paso.index + 1];
    notifyListeners();
  }

  void salirDelViaje() {
    _paso = null;
    notifyListeners();
  }

  /// Después de cualquier cambio de origen o destino: pasa al campo que
  /// falta (primero el destino) y, si están los dos, busca y elige la mejor
  /// línea.
  void _actualizar() {
    _paso = null;
    if (_destino == null) {
      _campoActivo = CampoViaje.hasta;
    } else if (_origen == null) {
      _campoActivo = CampoViaje.desde;
    }
    final origen = _origen;
    final destino = _destino;
    if (!_cargado || origen == null || destino == null) {
      _opciones = const [];
      _muyCerca = false;
      _elegida = null;
      if (_cargado) _estado = EstadoViaje.vacio;
    } else {
      final resultado = buscarOpciones(
        origen: origen.posicion,
        destino: destino.posicion,
        rutas: _rutas,
        paraderos: _paraderos,
      );
      _opciones = resultado.opciones;
      _muyCerca = resultado.muyCerca;
      _elegida = _opciones.firstOrNull;
      _estado = _opciones.isEmpty
          ? EstadoViaje.sinResultados
          : EstadoViaje.conResultados;
    }
    notifyListeners();
  }
}
