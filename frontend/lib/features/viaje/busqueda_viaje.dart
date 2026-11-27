import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../data/lugares/indice_lugares.dart';
import '../../data/models/eta.dart';
import '../../data/models/lugar.dart';
import '../../data/models/paradero.dart';
import '../../data/models/ruta.dart';

export '../../data/lugares/indice_lugares.dart';
export '../../data/models/lugar.dart';

/// Lógica del buscador "¿A dónde vas?". Es Dart puro (sin widgets): recibe
/// las rutas y sus paraderos tal como los entrega RutasRepository.
///
/// La búsqueda es por cercanía a los paraderos, no por el recorrido real:
/// las líneas son de ida y vuelta y el orden de los paraderos es aproximado,
/// así que no se filtra por sentido.

/// Lo máximo que se le pide caminar al pasajero hasta el paradero (y desde
/// el paradero de bajada hasta su destino), en metros.
const caminataMaximaMetros = 600.0;

/// Velocidad de una persona caminando: unos 4.8 km/h.
const velocidadCaminataMetrosPorMinuto = 80.0;

/// Velocidad media de una combi en Piura con paradas y tráfico (unos
/// 18 km/h), para estimar cuánto dura el tramo en bus.
const velocidadBusMetrosPorMinuto = 300.0;

/// El bus no va en línea recta: el recorrido por las calles es, en
/// promedio, un 30 % más largo que la distancia entre paraderos.
const factorRecorridoBus = 1.3;

/// Si el origen y el destino están más cerca que esto, no se buscan líneas:
/// conviene ir caminando.
const distanciaParaCaminarMetros = 300.0;

/// Puntos más cercanos que esto se consideran el mismo al encuadrar el mapa.
const puntosIgualesMetros = 30.0;

/// Radio medio de la Tierra usado por la fórmula de Haversine.
const radioTierraMetros = 6371000.0;

/// Si el paradero queda más lejos que esto del trazado de su línea, el
/// trazado no se usa para medir el tramo en bus.
const paraderoFueraDelTrazadoMetros = 200.0;

/// Nombre de un punto tocado en el mapa lejos de toda calle conocida.
const nombrePuntoEnMapa = 'Punto en el mapa';

/// Nombre del origen cuando se toma del GPS del pasajero.
const nombreUbicacionActual = 'Tu ubicación';

/// Un punto tocado a menos de esta distancia del centro de una calle conocida
/// se llama "Cerca de {calle}".
const distanciaNombreCalleMetros = 250.0;

/// Distancia en línea recta entre dos puntos, en metros (fórmula de Haversine).
double distanciaMetros(LatLng a, LatLng b) {
  double radianes(double grados) => grados * math.pi / 180;
  final dLat = radianes(b.latitude - a.latitude);
  final dLon = radianes(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(radianes(a.latitude)) *
          math.cos(radianes(b.latitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * radioTierraMetros * math.asin(math.min(1, math.sqrt(h)));
}

/// Minutos a pie para recorrer [metros], redondeados hacia arriba.
int minutosAPie(double metros) =>
    (metros / velocidadCaminataMetrosPorMinuto).ceil();

/// Indica si todos los puntos están prácticamente en el mismo lugar (o hay
/// uno solo): en ese caso basta centrar el mapa en vez de encuadrarlo.
bool puntosCasiIguales(List<LatLng> puntos) =>
    puntos.every((p) => distanciaMetros(puntos.first, p) < puntosIgualesMetros);

LatLng posicionDe(Paradero paradero) =>
    LatLng(paradero.latitud, paradero.longitud);

/// Paradero de [paraderos] más cercano a [punto]. La lista no puede estar vacía.
Paradero paraderoMasCercano(List<Paradero> paraderos, LatLng punto) {
  return paraderos.reduce(
    (mejor, p) =>
        distanciaMetros(posicionDe(p), punto) <
            distanciaMetros(posicionDe(mejor), punto)
        ? p
        : mejor,
  );
}

/// Lugares únicos (por nombre, sin distinguir mayúsculas ni tildes) a partir
/// de los paraderos de las rutas. Si un nombre se repite, se queda la
/// coordenada del primero.
List<Lugar> construirCatalogo(
  List<Ruta> rutas,
  Map<int, List<Paradero>> paraderos,
) {
  final lugares = <String, Lugar>{};
  for (final ruta in rutas) {
    for (final p in paraderos[ruta.idRuta] ?? const <Paradero>[]) {
      lugares.putIfAbsent(
        normalizar(p.nombre),
        () => Lugar(p.nombre, posicionDe(p), tipo: TipoLugar.paradero),
      );
    }
  }
  return lugares.values.toList();
}

/// Cantidad de "Destinos rápidos" (accesos de un clic).
const cantidadDestinosRapidos = 6;

/// Lugares por los que pasan más líneas activas (accesos de un clic), como
/// máximo [cantidadDestinosRapidos]. A igual número de líneas, en el orden en que
/// aparecen. Usa la coordenada del primer paradero con ese nombre.
List<Lugar> lugaresFrecuentes(
  List<Ruta> rutas,
  Map<int, List<Paradero>> paraderos,
) {
  final lineas = <String, Set<int>>{};
  for (final ruta in rutas.where((r) => r.activa)) {
    for (final p in paraderos[ruta.idRuta] ?? const <Paradero>[]) {
      lineas.putIfAbsent(normalizar(p.nombre), () => {}).add(ruta.idRuta);
    }
  }
  final catalogo = construirCatalogo(
    rutas,
    paraderos,
  ).where((l) => lineas.containsKey(normalizar(l.nombre))).toList();
  int cantidad(Lugar l) => lineas[normalizar(l.nombre)]!.length;
  // El orden de List.sort no es estable: se desempata por posición.
  final indices = {for (final (i, l) in catalogo.indexed) l: i};
  catalogo.sort((a, b) {
    final porLineas = cantidad(b).compareTo(cantidad(a));
    return porLineas != 0 ? porLineas : indices[a]!.compareTo(indices[b]!);
  });
  return catalogo.take(cantidadDestinosRapidos).toList();
}

/// Una línea que sirve para el viaje: dónde subir, dónde bajar y cuánto
/// caminar.
class OpcionViaje {
  const OpcionViaje({
    required this.ruta,
    required this.sube,
    required this.baja,
    required this.metrosSubida,
    required this.metrosBajada,
    this.metrosPorTrazado,
    this.eta,
    this.paraderosIntermedios = const [],
    this.haciaDonde,
    this.fueraDeHorario = false,
  });

  final Ruta ruta;
  final Paradero sube;
  final Paradero baja;

  /// Tramo en bus medido sobre el recorrido de la línea por las calles, si
  /// se conoce (ver [metrosSobreTrazado]).
  final double? metrosPorTrazado;

  /// Próxima unidad de la línea según el backend, si se conoce.
  final Eta? eta;

  /// Paraderos por los que pasa entre [sube] y [baja], en el orden del
  /// viaje (ver [paraderosEntre]).
  final List<Paradero> paraderosIntermedios;

  /// Terminal hacia el que va la unidad que hay que tomar (el letrero de la
  /// combi), según el sentido del viaje en el orden de los paraderos.
  final String? haciaDonde;

  /// La línea no atiende a la hora de la búsqueda (ver [enServicio]).
  final bool fueraDeHorario;

  /// La misma opción con la próxima unidad [eta].
  OpcionViaje conEta(Eta? eta) => OpcionViaje(
    ruta: ruta,
    sube: sube,
    baja: baja,
    metrosSubida: metrosSubida,
    metrosBajada: metrosBajada,
    metrosPorTrazado: metrosPorTrazado,
    eta: eta,
    paraderosIntermedios: paraderosIntermedios,
    haciaDonde: haciaDonde,
    fueraDeHorario: fueraDeHorario,
  );

  /// Caminata del origen al paradero de subida.
  final double metrosSubida;

  /// Caminata del paradero de bajada al destino.
  final double metrosBajada;

  double get metrosTotales => metrosSubida + metrosBajada;
  int get minutosSubida => minutosAPie(metrosSubida);
  int get minutosBajada => minutosAPie(metrosBajada);

  /// La espera viene de unidades en vivo (pasajeros compartiendo el GPS).
  bool get esperaEnVivo => eta != null && !eta!.simulado;

  /// Cuánto tarda en venir la unidad: el ETA real si hay unidades en vivo;
  /// si no, la espera promedio (la mitad de la frecuencia); si tampoco se
  /// conoce la frecuencia, el ETA simulado del backend; si no, 0.
  int get minutosEspera {
    final eta = this.eta;
    if (eta != null && !eta.simulado) return eta.minutos;
    final frecuencia = ruta.frecuenciaMinutos;
    if (frecuencia != null) return (frecuencia / 2).ceil();
    return eta?.minutos ?? 0;
  }

  /// Tramo en bus: sobre el trazado si se conoce; si no, la línea recta
  /// entre paraderos por [factorRecorridoBus] (aproximado).
  double get metrosEnBus =>
      metrosPorTrazado ??
      distanciaMetros(posicionDe(sube), posicionDe(baja)) * factorRecorridoBus;

  /// Minutos del tramo en bus a [velocidadBusMetrosPorMinuto].
  int get minutosEnBus => (metrosEnBus / velocidadBusMetrosPorMinuto).ceil();

  /// Duración aproximada de todo el viaje, de puerta a puerta.
  int get minutosTotales =>
      minutosSubida + minutosEspera + minutosEnBus + minutosBajada;

  double? get pasaje => ruta.pasaje;
  int? get frecuenciaMinutos => ruta.frecuenciaMinutos;
  String? get empresa => ruta.empresa;
  String? get tipoServicio => ruta.tipoServicio;
}

/// Resultado de una búsqueda.
class ResultadoBusqueda {
  const ResultadoBusqueda(this.opciones, {this.muyCerca = false});

  /// Líneas que sirven, de la más conveniente a la menos conveniente.
  final List<OpcionViaje> opciones;

  /// El origen y el destino están a menos de [distanciaParaCaminarMetros].
  final bool muyCerca;
}

/// Busca las líneas activas que pasan a menos de [caminataMaximaMetros] del
/// origen y del destino. Se ordenan por caminata total y, a igual caminata,
/// por frecuencia, pasaje (los datos que faltan van al final) y nombre.
ResultadoBusqueda buscarOpciones({
  required LatLng origen,
  required LatLng destino,
  required List<Ruta> rutas,
  required Map<int, List<Paradero>> paraderos,
  Map<int, List<LatLng>> trazados = const {},
  DateTime? ahora,
}) {
  if (distanciaMetros(origen, destino) < distanciaParaCaminarMetros) {
    return const ResultadoBusqueda([], muyCerca: true);
  }
  final opciones = <OpcionViaje>[];
  for (final ruta in rutas) {
    final lista = paraderos[ruta.idRuta] ?? const <Paradero>[];
    if (!ruta.activa || lista.length < 2) continue;
    final sube = paraderoMasCercano(lista, origen);
    final baja = paraderoMasCercano(lista, destino);
    final metrosSubida = distanciaMetros(origen, posicionDe(sube));
    final metrosBajada = distanciaMetros(posicionDe(baja), destino);
    if (sube.idParadero == baja.idParadero ||
        metrosSubida > caminataMaximaMetros ||
        metrosBajada > caminataMaximaMetros) {
      continue;
    }
    opciones.add(
      OpcionViaje(
        ruta: ruta,
        sube: sube,
        baja: baja,
        metrosSubida: metrosSubida,
        metrosBajada: metrosBajada,
        metrosPorTrazado: metrosSobreTrazado(
          trazados[ruta.idRuta] ?? const <LatLng>[],
          posicionDe(sube),
          posicionDe(baja),
        ),
        paraderosIntermedios: paraderosEntre(lista, sube, baja),
        // Los paraderos van del inicio al final de la línea: si se sube antes
        // de donde se baja, se toma la que va hacia el final.
        haciaDonde: sube.ordenSecuencial <= baja.ordenSecuencial
            ? ruta.puntoFinal
            : ruta.puntoInicio,
        fueraDeHorario: ahora != null && enServicio(ruta, ahora) == false,
      ),
    );
  }
  opciones.sort(_compararOpciones);
  return ResultadoBusqueda(opciones);
}

int _compararOpciones(OpcionViaje a, OpcionViaje b) {
  // Las que no atienden a esta hora, al final.
  if (a.fueraDeHorario != b.fueraDeHorario) return a.fueraDeHorario ? 1 : -1;
  final porCaminata = a.metrosTotales.compareTo(b.metrosTotales);
  if (porCaminata != 0) return porCaminata;
  final porFrecuencia = _compararNulosAlFinal(
    a.frecuenciaMinutos,
    b.frecuenciaMinutos,
  );
  if (porFrecuencia != 0) return porFrecuencia;
  final porPasaje = _compararNulosAlFinal(a.pasaje, b.pasaje);
  if (porPasaje != 0) return porPasaje;
  return a.ruta.nombre.compareTo(b.ruta.nombre);
}

int _compararNulosAlFinal(num? a, num? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Metros que recorre la línea por su [trazado] entre los puntos del
/// trazado más cercanos a [desde] y a [hasta]. Las líneas son de ida y
/// vuelta y no se conoce el sentido, así que se mide el tramo entre esos
/// dos puntos. Devuelve null si no hay trazado o si alguno de los paraderos
/// queda a más de [paraderoFueraDelTrazadoMetros] de él.
double? metrosSobreTrazado(List<LatLng> trazado, LatLng desde, LatLng hasta) {
  if (trazado.length < 2) return null;
  int? masCercano(LatLng punto) {
    var indice = 0;
    var mejor = double.infinity;
    for (final (i, p) in trazado.indexed) {
      final d = distanciaMetros(punto, p);
      if (d < mejor) {
        mejor = d;
        indice = i;
      }
    }
    return mejor <= paraderoFueraDelTrazadoMetros ? indice : null;
  }

  final a = masCercano(desde);
  final b = masCercano(hasta);
  if (a == null || b == null) return null;
  final inicio = math.min(a, b);
  final fin = math.max(a, b);
  var metros = 0.0;
  for (var i = inicio; i < fin; i++) {
    metros += distanciaMetros(trazado[i], trazado[i + 1]);
  }
  return metros;
}

/// Paraderos de [paraderos] entre [sube] y [baja] (sin incluirlos), según
/// su orden en la línea y en el sentido del viaje: si se sube después de
/// donde se baja, se recorren al revés.
List<Paradero> paraderosEntre(
  List<Paradero> paraderos,
  Paradero sube,
  Paradero baja,
) {
  final ordenados = [...paraderos]
    ..sort((a, b) => a.ordenSecuencial.compareTo(b.ordenSecuencial));
  final i = ordenados.indexWhere((p) => p.idParadero == sube.idParadero);
  final j = ordenados.indexWhere((p) => p.idParadero == baja.idParadero);
  if (i < 0 || j < 0) return const [];
  return i < j
      ? ordenados.sublist(i + 1, j)
      : ordenados.sublist(j + 1, i).reversed.toList();
}

/// Si [ruta] atiende a la hora de [ahora], según su horario ("06:00–21:00",
/// con raya o guion; si el cierre es antes que la apertura, pasa la
/// medianoche). Devuelve null si no tiene horario o no se entiende.
bool? enServicio(Ruta ruta, DateTime ahora) {
  final horario = ruta.horario;
  if (horario == null) return null;
  final partes = RegExp(
    r'^\s*(\d{1,2}):(\d{2})\s*[–—-]\s*(\d{1,2}):(\d{2})\s*$',
  ).firstMatch(horario);
  if (partes == null) return null;
  int minutos(int grupo) =>
      int.parse(partes.group(grupo)!) * 60 +
      int.parse(partes.group(grupo + 1)!);
  final abre = minutos(1);
  final cierra = minutos(3);
  final hora = ahora.hour * 60 + ahora.minute;
  return abre <= cierra
      ? hora >= abre && hora <= cierra
      : hora >= abre || hora <= cierra;
}
