import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/eta.dart';
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

/// Aviso de la guía cuando el pasajero va a bordo y hay GPS.
enum AvisoBajada {
  /// El próximo paradero es donde se baja.
  proxima,

  /// Está a menos de [distanciaParaBajarseMetros] del paradero de bajada.
  aqui,
}

/// Distancia al paradero de bajada a la que se avisa "Bájate aquí".
const distanciaParaBajarseMetros = 150.0;

/// Estado del buscador "¿A dónde vas?". Pide las rutas y los paraderos de
/// todas ellas una sola vez (en paralelo) y los guarda en memoria. Primero se
/// pide el destino y luego el origen (si hay GPS, el origen es la ubicación
/// actual); con los dos, busca sola y elige la mejor línea. Solo depende de la interfaz RutasRepository.
class PlanificadorViaje extends ChangeNotifier {
  PlanificadorViaje(
    this._repository, {
    this.lugaresConocidos = const [],
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? relojPorDefecto,
       _calles = [
         for (final l in lugaresConocidos)
           if (l.tipo == TipoLugar.calle) l,
       ];

  /// Base propia de calles y lugares de Piura que se suma a los paraderos
  /// en las sugerencias (lib/data/lugares/lugares_piura.dart).
  final List<Lugar> lugaresConocidos;
  final List<Lugar> _calles;

  final RutasRepository _repository;

  /// Hora actual, para saber qué líneas atienden.
  final DateTime Function() _reloj;

  /// Reloj que usan los planificadores creados sin uno propio. Las pruebas
  /// lo fijan (test/flutter_test_config.dart) para no depender de la hora
  /// en que se corren.
  static DateTime Function() relojPorDefecto = DateTime.now;

  List<Ruta> _rutas = const [];
  Map<int, List<Paradero>> _paraderos = const {};
  Map<int, List<LatLng>> _trazados = const {};
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

  /// Próxima unidad de cada línea ya pedida (null si el backend no la dio)
  /// y las que se están pidiendo.
  final Map<int, Eta?> _etas = {};
  final Set<int> _pidiendoEta = {};

  /// El mapa se cerró: lo que llegue después ya no se muestra.
  bool _descartado = false;

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  /// Última posición del GPS del pasajero (null si no hay permiso o señal).
  LatLng? _ubicacionActual;

  /// true si el pasajero tocó el origen (lo eligió, lo borró o lo cambió):
  /// desde entonces el GPS ya no lo reemplaza, hasta [limpiar].
  bool _origenManual = false;
  PasoViaje? _paso;
  int? _restantes;
  AvisoBajada? _aviso;

  /// Se llama una vez cada vez que aparece un aviso nuevo para bajarse (el
  /// mapa lo usa para vibrar y sonar).
  void Function(AvisoBajada aviso)? alAvisar;

  EstadoViaje get estado => _estado;
  Lugar? get origen => _origen;
  Lugar? get destino => _destino;
  CampoViaje get campoActivo => _campoActivo;
  List<Lugar> get catalogo => _catalogo;

  /// Rutas ya cargadas (para elegir la línea al reportar un cambio).
  List<Ruta> get rutas => _rutas;

  /// Lugares por los que pasan más líneas, para elegirlos con un clic.
  List<Lugar> get frecuentes => _frecuentes;
  List<OpcionViaje> get opciones => _opciones;
  bool get muyCerca => _muyCerca;
  OpcionViaje? get elegida => _elegida;

  /// Paso actual de la guía, o null si no hay un viaje iniciado.
  PasoViaje? get paso => _paso;

  /// A bordo y con GPS: paraderos que faltan hasta el de bajada. Null si no
  /// se va a bordo o no hay ubicación.
  int? get paraderosRestantes => _restantes;

  /// A bordo y con GPS: aviso para bajarse, o null si todavía falta.
  AvisoBajada? get avisoBajada => _aviso;

  /// Paraderos de una ruta ya cargados en memoria.
  List<Paradero> paraderosDe(int idRuta) =>
      _paraderos[idRuta] ?? const <Paradero>[];

  /// Recorrido por las calles de una ruta (vacío si no se conoce).
  List<LatLng> trazadoDe(int idRuta) => _trazados[idRuta] ?? const <LatLng>[];

  List<Lugar> sugerencias(String consulta) => _indice.sugerir(consulta);

  /// Pide las rutas y los paraderos de todas ellas. Si ya se cargaron, no
  /// vuelve a pedirlos.
  Future<void> cargar() async {
    if (_cargado) return;
    _estado = EstadoViaje.cargando;
    notifyListeners();
    try {
      final rutas = await _repository.listar();
      final (listas, trazados) = await (
        Future.wait(rutas.map((r) => _repository.paraderos(r.idRuta))),
        Future.wait(rutas.map((r) => _repository.trazado(r.idRuta))),
      ).wait;
      _rutas = rutas;
      _paraderos = {
        for (final (i, ruta) in rutas.indexed) ruta.idRuta: listas[i],
      };
      _trazados = {
        for (final (i, ruta) in rutas.indexed) ruta.idRuta: trazados[i],
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
    _origenManual = true;
    _origen = lugar;
    _actualizar();
  }

  /// Recibe la posición del GPS. Mientras el pasajero no elija otro origen,
  /// se usa como "Tu ubicación": así basta con escribir el destino. Con el
  /// destino ya elegido solo se guarda: el viaje buscado, la línea elegida
  /// y la guía no cambian mientras el pasajero camina.
  void usarUbicacionActual(LatLng punto) {
    _ubicacionActual = punto;
    if (_paso == PasoViaje.aBordo) {
      _seguirABordo(punto);
      notifyListeners();
      return;
    }
    if (_origenManual || _destino != null && _origen != null) return;
    final origen = _origen;
    if (origen != null && origen.posicion == punto) return;
    _origen = Lugar(nombreUbicacionActual, punto);
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
      _origenManual = true;
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
    _origenManual = true;
    final origen = _origen;
    _origen = _destino;
    _destino = origen;
    _actualizar();
  }

  /// Deja todo como al inicio: sin destino y, si se conoce, con la
  /// ubicación actual como origen.
  void limpiar() {
    _origenManual = false;
    final aqui = _ubicacionActual;
    _origen = aqui == null ? null : Lugar(nombreUbicacionActual, aqui);
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
    _limpiarABordo();
    notifyListeners();
  }

  void avanzarPaso() {
    final paso = _paso;
    if (paso == null || paso == PasoViaje.llegaste) return;
    _paso = PasoViaje.values[paso.index + 1];
    _limpiarABordo();
    final aqui = _ubicacionActual;
    if (_paso == PasoViaje.aBordo && aqui != null) _seguirABordo(aqui);
    notifyListeners();
  }

  void salirDelViaje() {
    _paso = null;
    _limpiarABordo();
    notifyListeners();
  }

  void _limpiarABordo() {
    _restantes = null;
    _aviso = null;
  }

  /// A bordo: el paradero de la línea más cercano a [punto] dice cuántos
  /// faltan. Avisa "en la próxima" cuando falta uno y "aquí" cerca del de
  /// bajada; cada aviso se da una sola vez y no vuelve atrás.
  void _seguirABordo(LatLng punto) {
    final o = _elegida;
    if (o == null) return;
    final camino = [o.sube, ...o.paraderosIntermedios, o.baja];
    var cercano = 0;
    var mejor = double.infinity;
    for (final (i, p) in camino.indexed) {
      final d = distanciaMetros(punto, posicionDe(p));
      if (d < mejor) {
        mejor = d;
        cercano = i;
      }
    }
    final cerca =
        distanciaMetros(punto, posicionDe(o.baja)) <=
        distanciaParaBajarseMetros;
    final restantes = cerca ? 0 : camino.length - 1 - cercano;
    _restantes = restantes;
    final aviso = cerca
        ? AvisoBajada.aqui
        : restantes <= 1
        ? AvisoBajada.proxima
        : null;
    final anterior = _aviso;
    if (aviso == null || (anterior != null && aviso.index <= anterior.index)) {
      return;
    }
    _aviso = aviso;
    alAvisar?.call(aviso);
  }

  /// Después de cualquier cambio de origen o destino: pasa al campo que
  /// falta (primero el destino) y, si están los dos, busca y elige la mejor
  /// línea.
  void _actualizar() {
    _paso = null;
    _limpiarABordo();
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
        trazados: _trazados,
        ahora: _reloj(),
      );
      _opciones = [
        for (final o in resultado.opciones) o.conEta(_etas[o.ruta.idRuta]),
      ];
      _muyCerca = resultado.muyCerca;
      _elegida = _opciones.firstOrNull;
      _pedirEtas();
      _estado = _opciones.isEmpty
          ? EstadoViaje.sinResultados
          : EstadoViaje.conResultados;
    }
    notifyListeners();
  }

  /// Pide al backend la próxima unidad de las líneas que sirven y que aún no
  /// se pidieron; al llegar, se suma a la espera de cada opción.
  Future<void> _pedirEtas() async {
    final repo = _repository;
    if (repo is! FuenteEta) return;
    final fuente = repo as FuenteEta;
    final ids = [
      for (final o in _opciones)
        if (!_etas.containsKey(o.ruta.idRuta) &&
            _pidiendoEta.add(o.ruta.idRuta))
          o.ruta.idRuta,
    ];
    if (ids.isEmpty) return;
    // Un pedido que falla no se guarda: se vuelve a pedir en la próxima
    // búsqueda.
    final etas = await Future.wait(
      ids.map(
        (id) => fuente
            .eta(id)
            .then<(bool, Eta?)>((eta) => (true, eta))
            .catchError((Object _) => (false, null)),
      ),
    );
    for (final (i, id) in ids.indexed) {
      final (llego, eta) = etas[i];
      if (llego) _etas[id] = eta;
      _pidiendoEta.remove(id);
    }
    if (_descartado) return;
    // Con la espera real el orden puede cambiar; la elegida se mantiene para
    // no mover lo que el pasajero está mirando.
    final elegida = _elegida?.ruta.idRuta;
    _opciones = [for (final o in _opciones) o.conEta(_etas[o.ruta.idRuta])]
      ..sort(compararOpciones);
    _elegida = _opciones.where((o) => o.ruta.idRuta == elegida).firstOrNull;
    notifyListeners();
  }
}
