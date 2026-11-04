import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/app.dart';
import 'package:piurago/core/routes.dart';
import 'package:piurago/data/rutas_repository.dart';
import 'package:piurago/data/ubicacion/servicio_ubicacion.dart';
import 'package:piurago/features/map/ubicacion_usuario.dart';

const _piura = LatLng(-5.1950, -80.6300);
const _enPiura = PosicionUsuario(_piura, 25);

/// Servicio que falla siempre (por ejemplo, sin plugin o en un sitio sin
/// HTTPS): la app debe seguir funcionando sin ubicación.
class _ServicioRoto extends ServicioUbicacion {
  @override
  bool get esWeb => false;

  @override
  Future<EstadoPermisoUbicacion> verificar() => throw Exception('sin GPS');

  @override
  Future<EstadoPermisoUbicacion> solicitar() => throw Exception('sin GPS');

  @override
  Stream<PosicionUsuario> posiciones({int distanceFilter = 10}) =>
      Stream.error(Exception('sin GPS'));

  @override
  Future<bool> abrirAjustesApp() => throw Exception('sin GPS');

  @override
  Future<bool> abrirAjustesUbicacion() => throw Exception('sin GPS');
}

void fijarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

NavigatorState navegador(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

/// Abre la app y va al mapa de una ruta (con [idRuta]) o al de Planificar
/// viaje (sin él).
Future<void> abrirMapa(
  WidgetTester tester,
  ServicioUbicacion servicio, {
  int? idRuta,
  SesionUbicacion? sesion,
}) async {
  await tester.pumpWidget(
    PiuraGoApp(
      rutasRepository: const FakeRutasRepository(),
      mostrarMapaBase: false,
      servicioUbicacion: servicio,
      sesionUbicacion: sesion ?? SesionUbicacion(),
    ),
  );
  await tester.pumpAndSettle();
  navegador(tester).pushReplacementNamed(AppRoutes.mapa, arguments: idRuta);
  await tester.pumpAndSettle();
}

final botonMiUbicacion = find.byTooltip('Mi ubicación');
final marcador = find.byKey(const ValueKey('marcador-mi-ubicacion'));
final activarUbicacion = find.text('Activar ubicación');

LatLng centroDelMapa(WidgetTester tester) => tester
    .widget<FlutterMap>(find.byType(FlutterMap))
    .mapController!
    .camera
    .center;

/// Crea el controlador y lo inicia como al abrir el mapa.
Future<UbicacionUsuario> abrir(
  FakeServicioUbicacion fake,
  SesionUbicacion sesion,
) async {
  final ubicacion = UbicacionUsuario(fake, sesion: sesion);
  addTearDown(ubicacion.dispose);
  await ubicacion.iniciar();
  await Future<void>.delayed(Duration.zero);
  return ubicacion;
}

void main() {
  group('UbicacionUsuario al abrir el mapa', () {
    test('concedido: muestra la posición y centra sin pedir nada', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
        posicionAlEscuchar: _enPiura,
      );

      final ubicacion = await abrir(fake, SesionUbicacion());

      expect(fake.vecesSolicitado, 0);
      expect(ubicacion.posicion?.punto, _piura);
      expect(ubicacion.tomarCentro(), _piura);
      expect(ubicacion.tomarCentro(), isNull, reason: 'se centra una vez');
      expect(ubicacion.mostrarAviso, isFalse);
    });

    test('pendiente que acepta: pide el permiso solo y centra', () async {
      final fake = FakeServicioUbicacion(posicionAlEscuchar: _enPiura);

      final ubicacion = await abrir(fake, SesionUbicacion());

      expect(fake.vecesSolicitado, 1);
      expect(ubicacion.estado, EstadoPermisoUbicacion.concedido);
      expect(ubicacion.tomarCentro(), _piura);
      expect(ubicacion.mostrarAviso, isFalse);
    });

    test('pendiente que rechaza: muestra el aviso y no vuelve a pedir en la '
        'misma sesión', () async {
      final sesion = SesionUbicacion();
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );

      final primera = await abrir(fake, sesion);
      expect(fake.vecesSolicitado, 1);
      expect(primera.mostrarAviso, isTrue);

      final segunda = await abrir(fake, sesion);
      expect(fake.vecesSolicitado, 1, reason: 'sin segundo pedido');
      expect(segunda.mostrarAviso, isTrue);
    });

    test('en una sesión nueva vuelve a pedir', () async {
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );

      await abrir(fake, SesionUbicacion());
      await abrir(fake, SesionUbicacion());

      expect(fake.vecesSolicitado, 2);
    });

    test('reabrir tras aceptar: centra sin volver a pedir', () async {
      final sesion = SesionUbicacion();
      final fake = FakeServicioUbicacion(posicionAlEscuchar: _enPiura);

      await abrir(fake, sesion);
      final segunda = await abrir(fake, sesion);

      expect(fake.vecesSolicitado, 1);
      expect(segunda.tomarCentro(), _piura);
    });

    test('denegado para siempre: no pide, avisa y "Activar ubicación" abre '
        'los ajustes de la app', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.denegadoParaSiempre,
      );

      final ubicacion = await abrir(fake, SesionUbicacion());

      expect(fake.vecesSolicitado, 0);
      expect(ubicacion.mostrarAviso, isTrue);
      expect(ubicacion.puedeActivar, isTrue);
      await ubicacion.activar();
      expect(fake.vecesAjustesApp, 1);
    });

    test('denegado para siempre en web: explica el candado y no abre '
        'ajustes', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.denegadoParaSiempre,
        esWeb: true,
      );

      final ubicacion = await abrir(fake, SesionUbicacion());

      expect(fake.vecesSolicitado, 0);
      expect(ubicacion.puedeActivar, isFalse);
      expect(ubicacion.mensajeAviso, contains('candado'));
      await ubicacion.activar();
      expect(fake.vecesAjustesApp, 0);
    });

    test('GPS apagado: no pide, avisa y "Activar ubicación" abre los ajustes '
        'de ubicación', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.servicioDesactivado,
      );

      final ubicacion = await abrir(fake, SesionUbicacion());

      expect(fake.vecesSolicitado, 0);
      expect(ubicacion.mostrarAviso, isTrue);
      await ubicacion.activar();
      expect(fake.vecesAjustesUbicacion, 1);
    });

    test('si el servicio falla no se rompe ni muestra el aviso', () async {
      final ubicacion = UbicacionUsuario(
        _ServicioRoto(),
        sesion: SesionUbicacion(),
      );
      addTearDown(ubicacion.dispose);

      await ubicacion.iniciar();
      await ubicacion.miUbicacion();

      expect(ubicacion.posicion, isNull);
      expect(ubicacion.mostrarAviso, isFalse);
    });
  });

  group('Botón "Mi ubicación"', () {
    test('con denied vuelve a pedir el permiso aunque el pedido automático '
        'ya se usó', () async {
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      final ubicacion = await abrir(fake, SesionUbicacion());
      expect(fake.vecesSolicitado, 1);

      fake.respuestaSolicitud = EstadoPermisoUbicacion.concedido;
      await ubicacion.miUbicacion();
      fake.emitir(_enPiura);
      await Future<void>.delayed(Duration.zero);

      expect(fake.vecesSolicitado, 2);
      expect(ubicacion.estado, EstadoPermisoUbicacion.concedido);
      expect(ubicacion.mostrarAviso, isFalse);
      expect(ubicacion.tomarCentro(), _piura);
    });

    test('con la posición conocida centra sin pedir', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
        posicionAlEscuchar: _enPiura,
      );
      final ubicacion = await abrir(fake, SesionUbicacion());
      ubicacion.tomarCentro();

      await ubicacion.miUbicacion();

      expect(fake.vecesSolicitado, 0);
      expect(ubicacion.tomarCentro(), _piura);
    });

    test('si el permiso se revocó (vuelve a denied), pide de nuevo en vez de '
        'centrar en la posición vieja', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
        posicionAlEscuchar: _enPiura,
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      final ubicacion = await abrir(fake, SesionUbicacion());
      ubicacion.tomarCentro();

      // La persona quitó el permiso desde el candado o los ajustes.
      fake.estado = EstadoPermisoUbicacion.denegado;
      await ubicacion.miUbicacion();

      expect(fake.vecesSolicitado, 1);
      expect(ubicacion.estado, EstadoPermisoUbicacion.denegado);
      expect(ubicacion.mostrarAviso, isTrue);
      expect(ubicacion.tomarCentro(), isNull);
    });

    test('si el stream del GPS terminó, el botón se vuelve a suscribir y '
        'centra', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
      );
      final ubicacion = await abrir(fake, SesionUbicacion());
      fake.cerrarPosiciones();
      await Future<void>.delayed(Duration.zero);

      await ubicacion.miUbicacion();
      fake.emitir(_enPiura);
      await Future<void>.delayed(Duration.zero);

      expect(ubicacion.posicion?.punto, _piura);
      expect(ubicacion.tomarCentro(), _piura);
    });

    test('"Activar ubicación" con denied vuelve a pedir', () async {
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      final ubicacion = await abrir(fake, SesionUbicacion());

      await ubicacion.activar();

      expect(fake.vecesSolicitado, 2);
    });
  });

  group('Mapa de la ruta', () {
    const escritorio = Size(1366, 768);

    testWidgets('concedido: marcador con precisión y mapa centrado sin pedir '
        'nada', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
        posicionAlEscuchar: _enPiura,
      );
      await abrirMapa(tester, fake, idRuta: 2);

      expect(fake.vecesSolicitado, 0);
      expect(marcador, findsOneWidget);
      final circulo = tester
          .widget<CircleLayer>(find.byType(CircleLayer))
          .circles
          .single;
      expect(circulo.point, _piura);
      expect(circulo.radius, 25);
      expect(circulo.useRadiusInMeter, isTrue);
      expect(centroDelMapa(tester), _piura);

      // El marcador sigue al stream.
      const otra = LatLng(-5.1800, -80.6400);
      fake.emitir(const PosicionUsuario(otra, 10));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CircleLayer>(find.byType(CircleLayer))
            .circles
            .single
            .point,
        otra,
      );
    });

    testWidgets('pendiente que acepta: el permiso sale solo al abrir y el '
        'mapa se centra', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(posicionAlEscuchar: _enPiura);
      await abrirMapa(tester, fake, idRuta: 2);

      expect(fake.vecesSolicitado, 1);
      expect(marcador, findsOneWidget);
      expect(centroDelMapa(tester), _piura);
      expect(activarUbicacion, findsNothing);
    });

    testWidgets('pendiente que rechaza: la app sigue con un aviso y al '
        'reabrir el mapa no vuelve a pedir', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      await abrirMapa(tester, fake, idRuta: 2);

      expect(fake.vecesSolicitado, 1);
      expect(activarUbicacion, findsOneWidget);
      expect(find.text('RUTA SELECCIONADA'), findsOneWidget);
      expect(marcador, findsNothing);

      // Sale a la lista de rutas y vuelve a abrir el mapa (misma sesión).
      navegador(tester).pushReplacementNamed(AppRoutes.rutas);
      await tester.pumpAndSettle();
      navegador(tester).pushReplacementNamed(AppRoutes.mapa, arguments: 3);
      await tester.pumpAndSettle();

      expect(fake.vecesSolicitado, 1);
      expect(activarUbicacion, findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pumpAndSettle();
      expect(activarUbicacion, findsNothing);
    });

    testWidgets('botón "Mi ubicación" con denied pide el permiso, muestra el '
        'marcador y centra', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      await abrirMapa(tester, fake, idRuta: 2);
      expect(fake.vecesSolicitado, 1);

      fake.respuestaSolicitud = EstadoPermisoUbicacion.concedido;
      await tester.tap(botonMiUbicacion);
      await tester.pumpAndSettle();
      fake.emitir(_enPiura);
      await tester.pumpAndSettle();

      expect(fake.vecesSolicitado, 2);
      expect(marcador, findsOneWidget);
      expect(centroDelMapa(tester), _piura);
      expect(activarUbicacion, findsNothing);
    });

    testWidgets('denegado para siempre en Android: no pide y "Activar '
        'ubicación" abre los ajustes de la app', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.denegadoParaSiempre,
      );
      await abrirMapa(tester, fake, idRuta: 2);

      expect(fake.vecesSolicitado, 0);
      await tester.tap(activarUbicacion);
      await tester.pumpAndSettle();
      expect(fake.vecesAjustesApp, 1);
    });

    testWidgets('denegado para siempre en web: explica que se activa desde '
        'el candado', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.denegadoParaSiempre,
        esWeb: true,
      );
      await abrirMapa(tester, fake, idRuta: 2);

      expect(fake.vecesSolicitado, 0);
      expect(find.textContaining('candado'), findsOneWidget);
      expect(activarUbicacion, findsNothing);
    });

    testWidgets('GPS apagado: no pide y "Activar ubicación" abre los ajustes '
        'de ubicación', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.servicioDesactivado,
      );
      await abrirMapa(tester, fake, idRuta: 2);

      expect(fake.vecesSolicitado, 0);
      await tester.tap(activarUbicacion);
      await tester.pumpAndSettle();
      expect(fake.vecesAjustesUbicacion, 1);
    });
  });

  group('Mapa de Planificar viaje', () {
    for (final (nombre, tamano) in [
      ('escritorio', const Size(1366, 768)),
      ('celular', const Size(390, 844)),
    ]) {
      testWidgets('en $nombre, pendiente que acepta: pide solo, muestra el '
          'marcador y centra', (tester) async {
        fijarPantalla(tester, tamano);
        final fake = FakeServicioUbicacion(posicionAlEscuchar: _enPiura);
        await abrirMapa(tester, fake);

        expect(fake.vecesSolicitado, 1);
        expect(marcador, findsOneWidget);
        expect(centroDelMapa(tester), _piura);
      });

      testWidgets('en $nombre, el botón con denied pide el permiso', (
        tester,
      ) async {
        fijarPantalla(tester, tamano);
        final fake = FakeServicioUbicacion(
          respuestaSolicitud: EstadoPermisoUbicacion.denegado,
        );
        await abrirMapa(tester, fake);

        fake.respuestaSolicitud = EstadoPermisoUbicacion.concedido;
        await tester.tap(botonMiUbicacion);
        await tester.pumpAndSettle();
        fake.emitir(_enPiura);
        await tester.pumpAndSettle();

        expect(fake.vecesSolicitado, 2);
        expect(marcador, findsOneWidget);
        expect(centroDelMapa(tester), _piura);
      });
    }

    testWidgets('concedido: marcador y centrado sin pedir', (tester) async {
      fijarPantalla(tester, const Size(1366, 768));
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
        posicionAlEscuchar: _enPiura,
      );
      await abrirMapa(tester, fake);

      expect(fake.vecesSolicitado, 0);
      expect(marcador, findsOneWidget);
      expect(centroDelMapa(tester), _piura);
    });

    testWidgets('pasar de la ruta al planificador no vuelve a pedir', (
      tester,
    ) async {
      fijarPantalla(tester, const Size(1366, 768));
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      await abrirMapa(tester, fake, idRuta: 2);
      navegador(tester).pushReplacementNamed(AppRoutes.mapa);
      await tester.pumpAndSettle();

      expect(fake.vecesSolicitado, 1);
      expect(activarUbicacion, findsOneWidget);
      expect(find.text('¿A dónde vas?'), findsOneWidget);
    });
  });
}
