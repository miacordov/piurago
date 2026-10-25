import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import 'buscador_lugares.dart';

/// Buscador de lugares con Photon (https://photon.komoot.io), un
/// geocodificador de OpenStreetMap hecho para sugerir mientras se escribe.
///
/// Solo envía el texto escrito y el punto fijo de Piura
/// ([centroBusquedaPiura]) para ordenar los resultados: nunca la ubicación
/// del usuario. El servicio público es de uso justo; la dirección se cambia
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

  @override
  Future<List<Lugar>> buscar(String texto) async {
    final pedido = url.replace(
      queryParameters: {
        'q': expandirAbreviaturas(texto),
        'lat': '${centroBusquedaPiura.latitude}',
        'lon': '${centroBusquedaPiura.longitude}',
        'limit': '$maximoLugaresEnLinea',
        // Radio de la ciudad y más peso a la cercanía que a la fama: así la
        // Catedral de Piura sale antes que la de Buenos Aires, sin ocultar
        // los lugares de fuera.
        'zoom': '12',
        'location_bias_scale': '0.1',
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
