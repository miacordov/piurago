import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piurago/data/api/auth_service.dart';

void main() {
  group('AuthService', () {
    test('obtiene token anónimo si no hay sesión activa', () async {
      late http.Request pedidoCapturado;

      final cliente = MockClient((request) async {
        pedidoCapturado = request;
        return http.Response(
          jsonEncode({
            'token': 'mock-jwt-token-anonimo',
            'idUsuario': 99,
            'deviceUuid': 'device-test-123',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final auth = AuthService(
        cliente: cliente,
        baseUrl: Uri.parse('http://localhost:8080'),
        deviceUuidInicial: 'device-test-123',
      );

      final token = await auth.obtenerToken();

      expect(token, 'mock-jwt-token-anonimo');
      expect(pedidoCapturado.method, 'POST');
      expect(pedidoCapturado.url.path, '/api/usuarios/anonimo');
      expect(auth.estaAutenticado, isTrue);

      final body = jsonDecode(pedidoCapturado.body) as Map<String, dynamic>;
      expect(body['deviceUuid'], 'device-test-123');
      expect(body['tipoDispositivo'], 'WEB');
    });

    test('reutiliza el token en llamadas sucesivas sin repetir la petición', () async {
      int llamadas = 0;

      final cliente = MockClient((request) async {
        llamadas++;
        return http.Response(
          jsonEncode({
            'token': 'mock-jwt-token-1',
            'idUsuario': 1,
            'deviceUuid': 'uuid-1',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final auth = AuthService(
        cliente: cliente,
        baseUrl: Uri.parse('http://localhost:8080'),
      );

      final token1 = await auth.obtenerToken();
      final token2 = await auth.obtenerToken();

      expect(token1, 'mock-jwt-token-1');
      expect(token2, 'mock-jwt-token-1');
      expect(llamadas, 1);
    });

    test('iniciar sesión registrada actualiza el token y el email', () async {
      late http.Request pedidoLogin;

      final cliente = MockClient((request) async {
        pedidoLogin = request;
        return http.Response(
          jsonEncode({
            'token': 'jwt-usuario-registrado',
            'email': 'estudiante@utp.edu.pe',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final auth = AuthService(
        cliente: cliente,
        baseUrl: Uri.parse('http://localhost:8080'),
      );

      final exito = await auth.login('estudiante@utp.edu.pe', 'clave123');

      expect(exito, isTrue);
      expect(pedidoLogin.method, 'POST');
      expect(pedidoLogin.url.path, '/api/auth/login');
      expect(auth.emailActual, 'estudiante@utp.edu.pe');
      expect(await auth.obtenerToken(), 'jwt-usuario-registrado');
    });

    test('cerrar sesión limpia el token y el email', () async {
      final auth = AuthService(
        cliente: MockClient((_) async => http.Response('{}', 200)),
        baseUrl: Uri.parse('http://localhost:8080'),
      );
      auth.establecerTokenManualmente('token-manual', email: 'test@utp.edu.pe');

      expect(auth.estaAutenticado, isTrue);
      expect(auth.emailActual, 'test@utp.edu.pe');

      auth.logout();

      expect(auth.estaAutenticado, isFalse);
      expect(auth.emailActual, isNull);
    });
  });
}
