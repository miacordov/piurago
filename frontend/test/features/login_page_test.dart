import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piurago/app.dart';
import 'package:piurago/data/api/almacen_sesion.dart';
import 'package:piurago/data/api/auth_service.dart';
import 'package:piurago/data/models/eta.dart';
import 'package:piurago/data/rutas_repository.dart';

void fijarPantalla(WidgetTester tester) {
  tester.view.physicalSize = const Size(1366, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Backend falso de autenticación.
class Backend {
  final pedidos = <String>[];
  int estadoLogin = 200;
  int estadoRegistro = 200;
  bool sinRed = false;

  late final cliente = MockClient((request) async {
    pedidos.add(request.url.path);
    if (sinRed) throw http.ClientException('sin red');
    switch (request.url.path) {
      case '/api/usuarios/anonimo':
        return http.Response(jsonEncode({'token': 't-anonimo'}), 200);
      case '/api/auth/login':
        if (estadoLogin != 200) return http.Response('', estadoLogin);
        return http.Response(
          jsonEncode({'token': 't-login', 'email': 'ana@correo.com'}),
          200,
        );
      case '/api/auth/registro':
        if (estadoRegistro != 200) return http.Response('', estadoRegistro);
        return http.Response(
          jsonEncode({'token': 't-registro', 'email': 'ana@correo.com'}),
          200,
        );
    }
    return http.Response('', 404);
  });

  AuthService auth([AlmacenSesion? almacen]) => AuthService(
    cliente: cliente,
    baseUrl: Uri.parse('http://localhost:8080'),
    almacen: almacen ?? AlmacenSesionMemoria(),
  );
}

Future<void> abrir(WidgetTester tester, AuthService auth) async {
  await tester.pumpWidget(
    PiuraGoApp(
      authService: auth,
      rutasRepository: const FakeRutasRepository(),
      mostrarMapaBase: false,
    ),
  );
  await tester.pumpAndSettle();
}

final campoCorreo = find.byKey(const ValueKey('campo-correo'));
final campoContrasena = find.byKey(const ValueKey('campo-contrasena'));
final campoNombre = find.byKey(const ValueKey('campo-nombre'));

Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('iniciar sesión con el backend pasa a activar la ubicación', (
    tester,
  ) async {
    fijarPantalla(tester);
    final backend = Backend();
    final auth = backend.auth();
    await abrir(tester, auth);

    await tester.enterText(campoCorreo, 'ana@correo.com');
    await tester.enterText(campoContrasena, 'clave123');
    await tocar(tester, find.text('Iniciar sesión').last);

    expect(backend.pedidos, contains('/api/auth/login'));
    expect(auth.esRegistrado, isTrue);
    expect(find.text('Activa tu ubicación'), findsOneWidget);
  });

  testWidgets('con credenciales incorrectas avisa y no avanza', (tester) async {
    fijarPantalla(tester);
    final backend = Backend()..estadoLogin = 401;
    await abrir(tester, backend.auth());

    await tester.enterText(campoCorreo, 'ana@correo.com');
    await tester.enterText(campoContrasena, 'mala');
    await tocar(tester, find.text('Iniciar sesión').last);

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Activa tu ubicación'), findsNothing);
  });

  testWidgets('sin conexión con el servidor lo dice', (tester) async {
    fijarPantalla(tester);
    final backend = Backend()..sinRed = true;
    await abrir(tester, backend.auth());

    await tester.enterText(campoCorreo, 'ana@correo.com');
    await tester.enterText(campoContrasena, 'clave123');
    await tocar(tester, find.text('Iniciar sesión').last);

    expect(
      find.text(
        'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo '
        'de nuevo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Regístrate aquí" muestra el registro y crea la cuenta', (
    tester,
  ) async {
    fijarPantalla(tester);
    final backend = Backend();
    final auth = backend.auth();
    await abrir(tester, auth);

    await tocar(tester, find.text('Regístrate aquí'));
    expect(find.text('Crea tu cuenta'), findsOneWidget);

    await tester.enterText(campoNombre, 'Ana');
    await tester.enterText(campoCorreo, 'ana@correo.com');
    await tester.enterText(campoContrasena, 'clave123');
    await tocar(tester, find.text('Crear cuenta'));

    expect(backend.pedidos, contains('/api/auth/registro'));
    expect(auth.esRegistrado, isTrue);
    expect(find.text('Activa tu ubicación'), findsOneWidget);
  });

  testWidgets('si el registro falla lo explica', (tester) async {
    fijarPantalla(tester);
    final backend = Backend()..estadoRegistro = 400;
    await abrir(tester, backend.auth());

    await tocar(tester, find.text('Regístrate aquí'));
    await tester.enterText(campoNombre, 'Ana');
    await tester.enterText(campoCorreo, 'ana@correo.com');
    await tester.enterText(campoContrasena, 'clave123');
    await tocar(tester, find.text('Crear cuenta'));

    expect(
      find.text(
        'No pudimos crear la cuenta. Puede que ese correo ya esté registrado.',
      ),
      findsOneWidget,
    );

    await tocar(tester, find.text('Inicia sesión aquí'));
    expect(campoNombre, findsNothing);
  });

  testWidgets('como pasajero anónimo pide su token y avanza', (tester) async {
    fijarPantalla(tester);
    final backend = Backend();
    final auth = backend.auth();
    await abrir(tester, auth);

    await tocar(tester, find.text('Continuar como pasajero anónimo'));

    expect(backend.pedidos, contains('/api/usuarios/anonimo'));
    expect(auth.estaAutenticado, isTrue);
    expect(find.text('Activa tu ubicación'), findsOneWidget);
  });

  testWidgets('sin servidor, el pasajero anónimo entra igual (modo demo)', (
    tester,
  ) async {
    fijarPantalla(tester);
    final backend = Backend()..sinRed = true;
    await abrir(tester, backend.auth());

    await tocar(tester, find.text('Continuar como pasajero anónimo'));

    expect(find.text('Activa tu ubicación'), findsOneWidget);
  });

  testWidgets('con una sesión registrada guardada abre directo en Rutas', (
    tester,
  ) async {
    fijarPantalla(tester);
    final almacen = AlmacenSesionMemoria();
    final backend = Backend();
    final antes = backend.auth(almacen);
    await antes.login('ana@correo.com', 'clave123');

    final auth = backend.auth(almacen);
    await auth.restaurarSesion();
    await abrir(tester, auth);

    expect(find.text('Encuentra tu ruta'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsNothing);
  });

  test('el ETA se redondea a minutos enteros', () {
    expect(const Eta(minutos: 4, simulado: true).minutos, 4);
  });
}
