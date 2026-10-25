import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import 'buscador_lugares.dart';
import 'indice_lugares.dart';

/// Palabras con las que empieza el nombre de una vía.
const _tiposDeVia = {
  'jr',
  'jiron',
  'calle',
  'ca',
  'cl',
  'av',
  'avenida',
  'avda',
  'psje',
  'pasaje',
  'pje',
  'prol',
  'prolongacion',
  'carr',
  'carretera',
};

/// Recuadro de Piura metropolitana y alrededores (oeste, sur, este, norte):
/// Piura, Castilla, Veintiséis de Octubre y Catacaos. Lo de fuera no sirve
/// para viajar en las líneas, así que no se sugiere.
const recuadroPiura = '-80.8,-5.35,-80.5,-5.05';

/// Buscador de lugares con Photon (https://photon.komoot.io), un
/// geocodificador de OpenStreetMap hecho para sugerir mientras se escribe.
///
/// Solo envía el texto escrito, el punto fijo de Piura
/// ([centroBusquedaPiura]) para ordenar los resultados y el recuadro de
/// Piura metropolitana ([recuadroPiura]): nunca la ubicación del usuario. El servicio público es de uso justo; la dirección se cambia
/// con --dart-define=GEOCODER_URL. Ver docs/diseno/mapa-osm.md.
class PhotonBuscadorLugares implements BuscadorLugares {
  PhotonBuscadorLugares({http.Client? cliente, Uri? url})
    : _cliente = cliente ?? http.Client(),
      url = url ?? Uri.parse(urlPublica);

  static const urlPublica = 'https://photon.komoot.io/api/';

  /// Tiempo máximo de espera de una respuesta.
  static const tiempoMaximo = Duration(seconds: 8);

  final http.Client _cliente;
  final Uri url;

  @override
  String get atribucion =>
      'Búsqueda de lugares: Photon · © OpenStreetMap contributors';

  /// Si el texto empieza con un tipo de vía ("jr lima", "Av. Grau"), devuelve
  /// solo el nombre: en OpenStreetMap el Jr. Lima del centro es "Calle Lima",
  /// así que se busca "lima" entre las calles de Piura.
  static String? _nombreDeVia(String texto) {
    final palabras = texto.trim().split(RegExp(r'\s+'));
    if (palabras.length < 2) return null;
    final tipo = normalizar(palabras.first).replaceAll('.', '');
    return _tiposDeVia.contains(tipo) ? palabras.skip(1).join(' ') : null;
  }

  @override
  Future<List<Lugar>> buscar(String texto) async {
    final via = _nombreDeVia(texto);
    final pedido = url.replace(
      queryParameters: {
        'q': via ?? expandirAbreviaturas(texto),
        'lat': '${centroBusquedaPiura.latitude}',
        'lon': '${centroBusquedaPiura.longitude}',
        'limit': '$maximoLugaresEnLinea',
        // Radio de la ciudad y más peso a la cercanía que a la fama.
        'zoom': '12',
        'location_bias_scale': '0.1',
        'bbox': recuadroPiura,
        if (via != null) 'osm_tag': 'highway',
      },
    );
    final http.Response respuesta;
    try {
      respuesta = await _cliente
          .get(
            pedido,
            // En la web el navegador no deja cambiar el User-Agent.
            headers: kIsWeb
                ? const {}
                : const {'User-Agent': 'PiuraGo/0.1 (com.piurago.piurago)'},
          )
          .timeout(tiempoMaximo);
    } on TimeoutException {
      throw const BusquedaLugaresException('sin respuesta');
    } on http.ClientException catch (e) {
      throw BusquedaLugaresException(e.message);
    }
    if (respuesta.statusCode == 429) {
      throw const BusquedaLugaresException(
        'límite de uso',
        limiteExcedido: true,
      );
    }
    if (respuesta.statusCode != 200) {
      throw BusquedaLugaresException('HTTP ${respuesta.statusCode}');
    }
    try {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      final features = (datos as Map<String, dynamic>)['features'] as List;
      return [
        for (final f in features.cast<Map<String, dynamic>>()) ?_lugarDe(f),
      ];
    } on FormatException {
      throw const BusquedaLugaresException('respuesta inválida');
    } on TypeError {
      throw const BusquedaLugaresException('respuesta inválida');
    }
  }

  /// Convierte un resultado de Photon (GeoJSON, coordenadas [lon, lat]).
  /// Sin nombre se usa la calle y el número; sin ninguno, se descarta.
  static Lugar? _lugarDe(Map<String, dynamic> feature) {
    final p = (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final coordenadas = (feature['geometry'] as Map?)?['coordinates'] as List?;
    if (coordenadas == null || coordenadas.length < 2) return null;
    String? texto(String clave) {
      final valor = p[clave];
      return valor is String && valor.trim().isNotEmpty ? valor.trim() : null;
    }

    final calle = texto('street');
    final nombre =
        texto('name') ??
        [calle, texto('housenumber')].whereType<String>().join(' ');
    if (nombre.isEmpty) return null;

    // Dónde queda, sin repetir dos partes seguidas iguales
    // (por ejemplo, la ciudad y la región "Piura").
    final partes = <String>[];
    for (final parte in [
      if (texto('name') != null && calle != nombre) calle,
      texto('locality'),
      texto('city') ?? texto('district'),
      texto('state'),
      texto('country'),
    ].whereType<String>()) {
      if (partes.isEmpty || partes.last != parte) partes.add(parte);
    }

    return Lugar(
      nombre,
      LatLng(
        (coordenadas[1] as num).toDouble(),
        (coordenadas[0] as num).toDouble(),
      ),
      tipo: switch (texto('osm_key')) {
        'highway' => TipoLugar.calle,
        'place' => TipoLugar.zona,
        _ => TipoLugar.lugar,
      },
      detalle: partes.isEmpty ? null : partes.join(', '),
    );
  }
}
