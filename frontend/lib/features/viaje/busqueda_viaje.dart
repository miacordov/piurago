import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../data/lugares/indice_lugares.dart';
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

/// Nombre de un punto tocado en el mapa lejos de toda calle conocida.
const nombrePuntoEnMapa = 'Punto en el mapa';

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
  });

  final Ruta ruta;
  final Paradero sube;
  final Paradero baja;

  /// Caminata del origen al paradero de subida.
  final double metrosSubida;

  /// Caminata del paradero de bajada al destino.
  final double metrosBajada;

  double get metrosTotales => metrosSubida + metrosBajada;
  int get minutosSubida => minutosAPie(metrosSubida);
  int get minutosBajada => minutosAPie(metrosBajada);

  /// Espera promedio en el paradero: la mitad de la frecuencia (0 si no se
  /// conoce).
  int get minutosEspera => ((ruta.frecuenciaMinutos ?? 0) / 2).ceil();

  /// Tramo en bus, estimado con [factorRecorridoBus] y
  /// [velocidadBusMetrosPorMinuto]: es aproximado.
  int get minutosEnBus =>
      (distanciaMetros(posicionDe(sube), posicionDe(baja)) *
              factorRecorridoBus /
              velocidadBusMetrosPorMinuto)
          .ceil();

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
      ),
    );
  }
  opciones.sort(_compararOpciones);
  return ResultadoBusqueda(opciones);
}

int _compararOpciones(OpcionViaje a, OpcionViaje b) {
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
