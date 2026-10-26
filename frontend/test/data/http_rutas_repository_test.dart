import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piurago/data/api/auth_service.dart';
import 'package:piurago/data/api/http_rutas_repository.dart';
import 'package:piurago/data/rutas_repository.dart';

void main() {
  group('HttpRutasRepository', () {
    late AuthService authFake;

    setUp(() {
      authFake = AuthService(
        cliente: MockClient((_) async => http.Response('{}', 200)),
        baseUrl: Uri.parse('http://localhost:8080'),
      );
      authFake.establecerTokenManualmente('jwt-valido');
    });

    test('listar() consulta GET /api/rutas con Bearer token', () async {
      late http.Request pedidoCapturado;

      final cliente = MockClient((request) async {
        pedidoCapturado = request;
        return http.Response(
          jsonEncode([
            {
              'idRuta': 101,
              'codigo': 'RD-99',
              'nombre': 'Ruta Backend Real',
              'empresa': 'Transportes Piura',
              'tipoServicio': 'Regulada',
              'activa': true,
              'frecuenciaMinutos': 8,
              'pasaje': 2.50,
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HttpRutasRepository(
        cliente: cliente,
        baseUrl: Uri.parse('http://localhost:8080'),
        authService: authFake,
      );

      final rutas = await repo.listar();

      expect(rutas.length, 1);
      expect(rutas.first.codigo, 'RD-99');
      expect(rutas.first.nombre, 'Ruta Backend Real');
      expect(rutas.first.pasaje, 2.50);
      expect(pedidoCapturado.method, 'GET');
      expect(pedidoCapturado.url.path, '/api/rutas');
      expect(pedidoCapturado.headers['authorization'], 'Bearer jwt-valido');
      expect(repo.esDemostracion, isFalse);
    });

    test('paraderos(idRuta) consulta GET /api/rutas/{id}/paraderos', () async {
      late http.Request pedidoCapturado;

      final cliente = MockClient((request) async {
        pedidoCapturado = request;
        return http.Response(
          jsonEncode([
            {
              'idParadero': 501,
              'nombre': 'Óvalo Grau',
              'latitud': -5.1950,
              'longitud': -80.6300,
              'ordenSecuencial': 1,
            },
            {
              'idParadero': 502,
              'nombre': 'Plaza de Armas',
              'latitud': -5.2000,
              'longitud': -80.6250,
              'ordenSecuencial': 2,
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HttpRutasRepository(
        cliente: cliente,
        baseUrl: Uri.parse('http://localhost:8080'),
        authService: authFake,
      );

      final lista = await repo.paraderos(101);

      expect(lista.length, 2);
      expect(lista.first.nombre, 'Óvalo Grau');
      expect(lista.last.nombre, 'Plaza de Armas');
      expect(pedidoCapturado.url.path, '/api/rutas/101/paraderos');
      expect(pedidoCapturado.headers['authorization'], 'Bearer jwt-valido');
    });

    test('reportarGps() envía POST /api/reportes-gps con coordenadas y ruta', () async {
      late http.Request pedidoCapturado;

      final cliente = MockClient((request) async {
        pedidoCapturado = request;
        return http.Response(
          jsonEncode({
            'idReporte': 1001,
            'idUsuario': 1,
            'idRuta': 101,
            'latitud': -5.1944,
            'longitud': -80.6328,
            'fechaHora': '2026-10-26T15:30:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HttpRutasRepository(
        cliente: cliente,
        baseUrl: Uri.parse('http://localhost:8080'),
        authService: authFake,
      );

      final ok = await repo.reportarGps(
        idRuta: 101,
        latitud: -5.1944,
        longitud: -80.6328,
      );

      expect(ok, isTrue);
      expect(pedidoCapturado.method, 'POST');
      expect(pedidoCapturado.url.path, '/api/reportes-gps');
      expect(pedidoCapturado.headers['authorization'], 'Bearer jwt-valido');

      final body = jsonDecode(pedidoCapturado.body) as Map<String, dynamic>;
      expect(body['idRuta'], 101);
      expect(body['latitud'], -5.1944);
      expect(body['longitud'], -80.6328);
    });

    test('si el backend falla o da error de red, conmuta suavemente al repositorio fallback', () async {
      final clienteError = MockClient((_) async {
        throw http.ClientException('Error de conexión a http://localhost:8080');
      });

      final repo = HttpRutasRepository(
        cliente: clienteError,
        baseUrl: Uri.parse('http://localhost:8080'),
        authService: authFake,
        fallback: const FakeRutasRepository(),
      );

      final rutas = await repo.listar();

      // Debe entregar las rutas de prueba sin lanzar excepción
      expect(rutas.isNotEmpty, isTrue);
      expect(repo.esDemostracion, isTrue);

      final paraderos = await repo.paraderos(1);
      expect(paraderos.isNotEmpty, isTrue);
    });
  });
}
