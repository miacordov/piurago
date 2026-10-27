import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piurago/data/api/auth_service.dart';
import 'package:piurago/data/api/http_rutas_repository.dart';
import 'package:piurago/data/rutas_repository.dart';

/// En el backend (Neon) los ids de las rutas no son los mismos que en los
/// datos locales: la misma línea se reconoce por su código.
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

http.Response json(Object cuerpo) => http.Response(
  jsonEncode(cuerpo),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Rutas como las devuelve el backend: ids distintos a los locales.
final rutasBackend = [
  {
    'idRuta': 900,
    'codigo': 'RD-12',
    'nombre': 'UPIS Villa Rica - UPIS 11 de Enero',
  },
  {'idRuta': 22, 'codigo': 'I-18', 'nombre': 'Terminal Satélite - La Unión'},
];

void main() {
  group('eta()', () {
    test('lee minutos y origen SIMULADO del backend', () async {
      final repo = repositorio((request) async {
        expect(request.url.path, '/api/reportes-gps/eta/900');
        return json({
          'idRuta': 900,
          'minutosEstimados': 4.6,
          'origen': 'SIMULADO',
        });
      });

      final eta = await repo.eta(900);

      expect(eta!.minutos, 5);
      expect(eta.simulado, isTrue);
    });

    test('con reportes en vivo el origen es REAL', () async {
      final repo = repositorio(
        (_) async => json({'minutosEstimados': 2.0, 'origen': 'REAL'}),
      );
      final eta = await repo.eta(1);
      expect(eta!.minutos, 2);
      expect(eta.simulado, isFalse);
    });

    test('sin respuesta del backend no hay ETA', () async {
      final repo = repositorio((_) async => http.Response('', 500));
      expect(await repo.eta(1), isNull);
    });
  });

  group('trazado y paraderos se buscan por el código de la línea', () {
    test(
      'el trazado oficial de RD-12 sale aunque el backend use otro id',
      () async {
        const local = FakeRutasRepository();
        final rd12 = (await local.listar()).firstWhere(
          (r) => r.codigo == 'RD-12',
        );
        final repo = repositorio((_) async => json(rutasBackend));
        await repo.listar();

        expect(await repo.trazado(900), await local.trazado(rd12.idRuta));
        expect(await repo.trazado(900), isNotEmpty);
      },
    );

    test(
      'el id del backend no se confunde con el id local de otra ruta',
      () async {
        // El id 22 es RD-12 en los datos locales, pero en el backend es I-18,
        // que no tiene trazado oficial.
        final repo = repositorio((_) async => json(rutasBackend));
        await repo.listar();

        expect(await repo.trazado(22), isEmpty);
      },
    );

    test(
      'si el backend no tiene paraderos, usa los locales de la misma línea',
      () async {
        const local = FakeRutasRepository();
        final i18 = (await local.listar()).firstWhere(
          (r) => r.codigo == 'I-18',
        );
        final repo = repositorio((request) async {
          if (request.url.path == '/api/rutas') return json(rutasBackend);
          return json(<Object>[]);
        });
        await repo.listar();

        final paraderos = await repo.paraderos(22);

        expect(
          paraderos.map((p) => p.nombre),
          (await local.paraderos(i18.idRuta)).map((p) => p.nombre),
        );
      },
    );

    test('sin saber el código no inventa trazado', () async {
      final repo = repositorio((_) async => json(<Object>[]));
      expect(await repo.trazado(22), isEmpty);
    });
  });
}
