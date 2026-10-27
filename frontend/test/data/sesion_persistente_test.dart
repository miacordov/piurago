import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piurago/data/api/almacen_sesion.dart';
import 'package:piurago/data/api/auth_service.dart';

/// Backend falso: responde a anónimo, login y registro, y cuenta las
/// peticiones.
class BackendFalso {
  int peticiones = 0;
  int estadoLogin = 200;
  bool sinRed = false;

  late final cliente = MockClient((request) async {
    peticiones++;
    if (sinRed) throw http.ClientException('sin red');
    final ruta = request.url.path;
    if (ruta == '/api/usuarios/anonimo') {
      return http.Response(jsonEncode({'token': 'token-anonimo'}), 200);
    }
    if (ruta == '/api/auth/login') {
      if (estadoLogin != 200) return http.Response('', estadoLogin);
      final datos = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'token': 'token-registrado', 'email': datos['email']}),
        200,
      );
    }
    if (ruta == '/api/auth/registro') {
      final datos = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'token': 'token-nuevo', 'email': datos['email']}),
        200,
      );
    }
    return http.Response('', 404);
  });
}

AuthService crear(BackendFalso backend, AlmacenSesion almacen) => AuthService(
  cliente: backend.cliente,
  baseUrl: Uri.parse('http://localhost:8080'),
  almacen: almacen,
);

void main() {
  test('el identificador del dispositivo se guarda y se reutiliza', () async {
    final almacen = AlmacenSesionMemoria();
    final primera = crear(BackendFalso(), almacen);
    await primera.restaurarSesion();

    final segunda = crear(BackendFalso(), almacen);
    await segunda.restaurarSesion();

    expect(primera.deviceUuid, startsWith('piurago-dev-'));
    // Así no se crea un usuario anónimo nuevo en cada apertura de la app.
    expect(segunda.deviceUuid, primera.deviceUuid);
  });

  test('una sesión iniciada se recupera al volver a abrir la app', () async {
    final almacen = AlmacenSesionMemoria();
    final antes = crear(BackendFalso(), almacen);
    await antes.restaurarSesion();
    expect(await antes.login('ana@correo.com', 'clave123'), isTrue);

    final backend = BackendFalso();
    final despues = crear(backend, almacen);
    await despues.restaurarSesion();

    expect(despues.esRegistrado, isTrue);
    expect(despues.emailActual, 'ana@correo.com');
    expect(await despues.obtenerToken(), 'token-registrado');
    expect(backend.peticiones, 0);
  });

  test('registrarse también deja la sesión guardada', () async {
    final almacen = AlmacenSesionMemoria();
    final auth = crear(BackendFalso(), almacen);
    await auth.restaurarSesion();
    expect(await auth.registrar('Ana', 'ana@correo.com', 'clave123'), isTrue);

    final despues = crear(BackendFalso(), almacen);
    await despues.restaurarSesion();
    expect(despues.esRegistrado, isTrue);
    expect(await despues.obtenerToken(), 'token-nuevo');
  });

  test('el token anónimo se guarda: no se pide otro al volver', () async {
    final almacen = AlmacenSesionMemoria();
    final antes = crear(BackendFalso(), almacen);
    await antes.restaurarSesion();
    await antes.obtenerToken();

    final backend = BackendFalso();
    final despues = crear(backend, almacen);
    await despues.restaurarSesion();

    expect(despues.esRegistrado, isFalse);
    expect(await despues.obtenerToken(), 'token-anonimo');
    expect(backend.peticiones, 0);
  });

  test('cerrar sesión borra el token pero no el dispositivo', () async {
    final almacen = AlmacenSesionMemoria();
    final auth = crear(BackendFalso(), almacen);
    await auth.restaurarSesion();
    await auth.login('ana@correo.com', 'clave123');
    final dispositivo = auth.deviceUuid;

    await auth.cerrarSesion();

    final despues = crear(BackendFalso(), almacen);
    await despues.restaurarSesion();
    expect(despues.estaAutenticado, isFalse);
    expect(despues.esRegistrado, isFalse);
    expect(despues.deviceUuid, dispositivo);
  });

  test('distingue credenciales incorrectas de un fallo de red', () async {
    final backend = BackendFalso()..estadoLogin = 401;
    final auth = crear(backend, AlmacenSesionMemoria());

    expect(await auth.login('ana@correo.com', 'mala'), isFalse);
    expect(auth.ultimoFalloFueDeRed, isFalse);

    backend.sinRed = true;
    expect(await auth.login('ana@correo.com', 'clave123'), isFalse);
    expect(auth.ultimoFalloFueDeRed, isTrue);
  });
}
