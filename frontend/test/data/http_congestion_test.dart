import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piurago/data/api/auth_service.dart';
import 'package:piurago/data/api/http_rutas_repository.dart';
import 'package:piurago/data/models/resumen_congestion.dart';

HttpRutasRepository repositorio(
  Future<http.Response> Function(http.Request) responder,
) {
  final auth = AuthService(
    cliente: MockClient((_) async => http.Response('{}', 500)),
    baseUrl: Uri.parse('http://localhost:8080'),
  )..establecerTokenManualmente('token');
  return HttpRutasRepository(
    cliente: MockClient(responder),
    baseUrl: Uri.parse('http://localhost:8080'),
    authService: auth,
  );
}

/// Respuesta de GET /api/historico-congestion/resumen (ResumenCongestionDTO).
const resumenBackend = {
  'franjaHoraria': 'MEDIO_DIA',
  'diaSemana': 'MAR',
  'nivelGeneral': 'MEDIA',
  'velocidadPromedio': 14.5,
  'demoraPromedio': 1.74,
  'rutasConDatos': 3,
  'puntosCriticos': 9,
  'porFranja': [
    {'franjaHoraria': 'MANANA_PICO', 'nivel': 'ALTA', 'velocidadPromedio': 8.2},
    {'franjaHoraria': 'MEDIO_DIA', 'nivel': 'MEDIA', 'velocidadPromedio': 14.5},
    {'franjaHoraria': 'TARDE_PICO', 'nivel': null, 'velocidadPromedio': null},
    {'franjaHoraria': 'NOCHE', 'nivel': 'BAJA', 'velocidadPromedio': 27},
  ],
  'tramosCriticos': [
    {
      'codigoRuta': 'RD-10',
      'nombreRuta': 'UPIS San Gabriel Arcángel - Av. Raúl Mata La Cruz',
      'desde': 'Open Plaza',
      'hasta': 'Instituto Médico Soy Diabético',
      'velocidadPromedio': 6.0,
      'nivel': 'ALTA',
      'demoraMinutos': 4,
    },
  ],
};

void main() {
  test('pide el resumen de la franja y lee todos sus datos', () async {
    late Uri pedida;
    final repo = repositorio((request) async {
      pedida = request.url;
      expect(request.headers['Authorization'], 'Bearer token');
      return http.Response(
        jsonEncode(resumenBackend),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final resumen = await repo.resumenCongestion(franjaHoraria: 'MEDIO_DIA');

    expect(pedida.path, '/api/historico-congestion/resumen');
    expect(pedida.queryParameters['franjaHoraria'], 'MEDIO_DIA');
    expect(resumen!.franjaHoraria, 'MEDIO_DIA');
    expect(resumen.nivelGeneral, NivelCongestion.media);
    expect(resumen.velocidadPromedio, 14.5);
    expect(resumen.demoraPromedio, 1.74);
    expect(resumen.rutasConDatos, 3);
    expect(resumen.puntosCriticos, 9);
    expect(resumen.porFranja.map((f) => f.nivel), [
      NivelCongestion.alta,
      NivelCongestion.media,
      null,
      NivelCongestion.baja,
    ]);
    expect(resumen.porFranja.last.velocidadPromedio, 27.0);

    final tramo = resumen.tramosCriticos.single;
    expect(tramo.codigoRuta, 'RD-10');
    expect(tramo.desde, 'Open Plaza');
    expect(tramo.hasta, 'Instituto Médico Soy Diabético');
    expect(tramo.nivel, NivelCongestion.alta);
    expect(tramo.demoraMinutos, 4);
  });

  test(
    'sin franja no manda el parámetro: el backend usa la hora actual',
    () async {
      final repo = repositorio((request) async {
        expect(
          request.url.queryParameters.containsKey('franjaHoraria'),
          isFalse,
        );
        // Como Spring: JSON en UTF-8 sin charset en la cabecera.
        return http.Response.bytes(
          utf8.encode(jsonEncode(resumenBackend)),
          200,
        );
      });

      expect(await repo.resumenCongestion(), isNotNull);
    },
  );

  test('sin datos todavía, el nivel viene vacío', () async {
    final repo = repositorio(
      (_) async => http.Response(
        jsonEncode({
          'franjaHoraria': 'NOCHE',
          'diaSemana': 'DOM',
          'nivelGeneral': null,
          'velocidadPromedio': null,
          'demoraPromedio': null,
          'rutasConDatos': 0,
          'puntosCriticos': 0,
          'porFranja': [],
          'tramosCriticos': [],
        }),
        200,
      ),
    );

    final resumen = await repo.resumenCongestion();

    expect(resumen!.tieneDatos, isFalse);
    expect(resumen.nivelGeneral, isNull);
    expect(resumen.velocidadPromedio, isNull);
  });

  test('si el backend falla devuelve null', () async {
    final caido = repositorio((_) async => http.Response('error', 500));
    final sinRed = repositorio((_) async => throw http.ClientException('red'));

    expect(await caido.resumenCongestion(), isNull);
    expect(await sinRed.resumenCongestion(), isNull);
  });

  group('exportarCongestionExcel()', () {
    test('descarga el Excel del backend con el token', () async {
      final bytesExcel = [0x50, 0x4b, 0x03, 0x04, 1, 2, 3];
      final repo = repositorio((request) async {
        expect(request.url.path, '/api/historico-congestion/exportar');
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response.bytes(bytesExcel, 200);
      });

      expect(await repo.exportarCongestionExcel(), bytesExcel);
    });

    test('si el backend falla devuelve null', () async {
      final caido = repositorio((_) async => http.Response('error', 500));
      final sinRed = repositorio(
        (_) async => throw http.ClientException('red'),
      );

      expect(await caido.exportarCongestionExcel(), isNull);
      expect(await sinRed.exportarCongestionExcel(), isNull);
    });
  });
}
