import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/data/lugares/buscador_lugares.dart';
import 'package:piurago/data/lugares/buscador_lugares_prueba.dart';
import 'package:piurago/data/lugares/photon_buscador_lugares.dart';
import 'package:piurago/data/models/lugar.dart';

/// Respuesta de Photon con la forma real (GeoJSON, coordenadas [lon, lat]).
String respuestaPhoton(List<Map<String, Object?>> features) =>
    jsonEncode({'type': 'FeatureCollection', 'features': features});

Map<String, Object?> feature({
  required double lon,
  required double lat,
  Map<String, Object?> propiedades = const {},
}) {
  return {
    'type': 'Feature',
    'properties': propiedades,
    'geometry': {
      'type': 'Point',
      'coordinates': [lon, lat],
    },
  };
}

void main() {
  test('pide solo el texto y el punto fijo de Piura', () async {
    late http.Request pedido;
    final buscador = PhotonBuscadorLugares(
      cliente: MockClient((request) async {
        pedido = request;
        return http.Response(respuestaPhoton([]), 200);
      }),
    );

    await buscador.buscar('Real Plaza');

    expect(pedido.method, 'GET');
    expect(pedido.url.origin, 'https://photon.komoot.io');
    expect(pedido.url.path, '/api/');
    expect(pedido.url.queryParameters, {
      'q': 'Real Plaza',
      'lat': '-5.1945',
      'lon': '-80.6328',
      'limit': '$maximoLugaresEnLinea',
      'zoom': '12',
      'location_bias_scale': '0.1',
      // Solo Piura metropolitana: lo de fuera no sirve para las líneas.
      'bbox': '-80.8,-5.35,-80.5,-5.05',
    });
  });

  test('con un tipo de vía busca solo calles de Piura', () async {
    final pedidos = <Uri>[];
    final buscador = PhotonBuscadorLugares(
      cliente: MockClient((request) async {
        pedidos.add(request.url);
        return http.Response(respuestaPhoton([]), 200);
      }),
    );

    await buscador.buscar('jr lima');
    await buscador.buscar('Av. Grau');

    // "Jr. Lima" es "Calle Lima" en OpenStreetMap: se busca solo el nombre
    // entre las calles de Piura metropolitana.
    expect(pedidos[0].queryParameters['q'], 'lima');
    expect(pedidos[0].queryParameters['osm_tag'], 'highway');
    expect(pedidos[0].queryParameters['bbox'], '-80.8,-5.35,-80.5,-5.05');
    expect(pedidos[1].queryParameters['q'], 'Grau');
    expect(pedidos[1].queryParameters['osm_tag'], 'highway');
  });

  test('la dirección del servicio se puede cambiar', () async {
    late Uri url;
    final buscador = PhotonBuscadorLugares(
      url: Uri.parse('https://geocoder.ejemplo.pe/api'),
      cliente: MockClient((request) async {
        url = request.url;
        return http.Response(respuestaPhoton([]), 200);
      }),
    );

    await buscador.buscar('piura');

    expect(url.host, 'geocoder.ejemplo.pe');
    expect(url.path, '/api');
  });

  test('traduce las abreviaturas antes de buscar', () {
    expect(expandirAbreviaturas('jr ica'), 'jirón ica');
    expect(expandirAbreviaturas('Jr. Ica 450'), 'jirón Ica 450');
    expect(expandirAbreviaturas('av grau'), 'avenida grau');
    expect(expandirAbreviaturas('psje los olivos'), 'pasaje los olivos');
    expect(expandirAbreviaturas('urb santa ana'), 'urbanización santa ana');
    expect(expandirAbreviaturas('real plaza'), 'real plaza');
  });

  test('convierte cada resultado en un lugar con su detalle', () async {
    final buscador = PhotonBuscadorLugares(
      cliente: MockClient(
        (_) async => http.Response(
          respuestaPhoton([
            feature(
              lon: -80.6272688,
              lat: -5.1957446,
              propiedades: {
                'osm_key': 'highway',
                'name': 'Jirón Ica',
                'locality': 'Urbanización 4 de Enero',
                'city': 'Piura',
                'state': 'Piura',
                'country': 'Perú',
              },
            ),
            feature(
              lon: -80.64196,
              lat: -5.18470,
              propiedades: {
                'osm_key': 'shop',
                'name': 'Real Plaza Piura',
                'street': 'Avenida Sánchez Cerro',
                'city': 'Piura',
                'country': 'Perú',
              },
            ),
            feature(
              lon: -77.03,
              lat: -12.04,
              propiedades: {
                'osm_key': 'place',
                'name': 'Lima',
                'state': 'Lima',
                'country': 'Perú',
              },
            ),
            // Una dirección sin nombre: se arma con la calle y el número.
            feature(
              lon: -80.63,
              lat: -5.19,
              propiedades: {
                'street': 'Avenida Grau',
                'housenumber': '450',
                'city': 'Piura',
              },
            ),
            // Sin nombre ni calle: se descarta.
            feature(lon: -80.63, lat: -5.19),
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    final lugares = await buscador.buscar('ica');

    expect(lugares.map((l) => l.nombre), [
      'Jirón Ica',
      'Real Plaza Piura',
      'Lima',
      'Avenida Grau 450',
    ]);
    expect(lugares[0].posicion, const LatLng(-5.1957446, -80.6272688));
    expect(lugares[0].tipo, TipoLugar.calle);
    expect(lugares[0].detalle, 'Urbanización 4 de Enero, Piura, Perú');
    expect(lugares[1].tipo, TipoLugar.lugar);
    expect(lugares[1].detalle, 'Avenida Sánchez Cerro, Piura, Perú');
    expect(lugares[2].tipo, TipoLugar.zona);
    expect(lugares[2].detalle, 'Lima, Perú');
    expect(lugares[3].detalle, 'Piura');
  });

  test('un 429 avisa que se pasó el límite de uso', () async {
    final buscador = PhotonBuscadorLugares(
      cliente: MockClient((_) async => http.Response('', 429)),
    );
    await expectLater(
      buscador.buscar('piura'),
      throwsA(
        isA<BusquedaLugaresException>().having(
          (e) => e.limiteExcedido,
          'limiteExcedido',
          isTrue,
        ),
      ),
    );
  });

  test('un 5xx o un fallo de red es un error sin límite', () async {
    for (final cliente in [
      MockClient((_) async => http.Response('', 503)),
      MockClient((_) async => throw http.ClientException('sin red')),
      MockClient((_) async => http.Response('no es json', 200)),
    ]) {
      await expectLater(
        PhotonBuscadorLugares(cliente: cliente).buscar('piura'),
        throwsA(
          isA<BusquedaLugaresException>().having(
            (e) => e.limiteExcedido,
            'limiteExcedido',
            isFalse,
          ),
        ),
      );
    }
  });

  test('el buscador de prueba responde sin red', () async {
    const buscador = BuscadorLugaresPrueba();
    final lugares = await buscador.buscar('real');
    expect(lugares.first.nombre, 'Real Plaza Piura');
    expect(await buscador.buscar('zzzz'), isEmpty);
  });
}
