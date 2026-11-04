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

/// Abre el mapa de una ruta (con [idRuta]) o el de Planificar viaje (sin él).
Future<void> abrirMapa(
  WidgetTester tester,
  ServicioUbicacion servicio, {
  int? idRuta,
}) async {
  await tester.pumpWidget(
    PiuraGoApp(
      rutasRepository: const FakeRutasRepository(),
      mostrarMapaBase: false,
      servicioUbicacion: servicio,
    ),
  );
  await tester.pumpAndSettle();
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushReplacementNamed(AppRoutes.mapa, arguments: idRuta);
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

void main() {
  group('UbicacionUsuario', () {
    test('si el permiso ya estaba concedido escucha la posición sin '
        'mostrar el diálogo', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
      );
      final ubicacion = UbicacionUsuario(fake);
      addTearDown(ubicacion.dispose);

      await ubicacion.iniciar();
      fake.emitir(const PosicionUsuario(_piura, 15));
      await Future<void>.delayed(Duration.zero);

      expect(fake.vecesSolicitado, 0);
      expect(
        fake.ultimoDistanceFilter,
        ServicioUbicacion.distanciaMinimaPorDefecto,
      );
      expect(ubicacion.posicion?.punto, _piura);
      expect(ubicacion.mostrarAviso, isFalse);
    });

    test('al abrir el mapa sin permiso no muestra diálogo ni aviso', () async {
      final fake = FakeServicioUbicacion();
      final ubicacion = UbicacionUsuario(fake);
      addTearDown(ubicacion.dispose);

      await ubicacion.iniciar();

      expect(fake.vecesSolicitado, 0);
      expect(ubicacion.mostrarAviso, isFalse);
      expect(ubicacion.posicion, isNull);
    });

    test(
      'miUbicacion() pide el permiso y centra en la primera posición',
      () async {
        final fake = FakeServicioUbicacion();
        final ubicacion = UbicacionUsuario(fake);
        addTearDown(ubicacion.dispose);
        final centrados = <LatLng>[];
        ubicacion.centrados.listen(centrados.add);

        await ubicacion.miUbicacion();
        fake.emitir(const PosicionUsuario(_piura, 15));
        await Future<void>.delayed(Duration.zero);

        expect(fake.vecesSolicitado, 1);
        expect(ubicacion.estado, EstadoPermisoUbicacion.concedido);
        expect(centrados, [_piura]);

        // Con la posición ya conocida, centra sin volver a esperar al GPS.
        await ubicacion.miUbicacion();
        await Future<void>.delayed(Duration.zero);
        expect(centrados, [_piura, _piura]);
      },
    );

    test('si se deniega muestra el aviso y "Activar ubicación" vuelve a '
        'preguntar', () async {
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      final ubicacion = UbicacionUsuario(fake);
      addTearDown(ubicacion.dispose);

      await ubicacion.miUbicacion();
      expect(ubicacion.mostrarAviso, isTrue);

      fake.respuestaSolicitud = EstadoPermisoUbicacion.concedido;
      await ubicacion.activar();

      expect(fake.vecesSolicitado, 2);
      expect(ubicacion.estado, EstadoPermisoUbicacion.concedido);
      expect(ubicacion.mostrarAviso, isFalse);
    });

    test(
      'denegado para siempre en Android abre los ajustes de la app',
      () async {
        final fake = FakeServicioUbicacion(
          respuestaSolicitud: EstadoPermisoUbicacion.denegadoParaSiempre,
        );
        final ubicacion = UbicacionUsuario(fake);
        addTearDown(ubicacion.dispose);

        await ubicacion.miUbicacion();
        await ubicacion.activar();

        expect(fake.vecesAjustesApp, 1);
        expect(fake.vecesAjustesUbicacion, 0);
      },
    );

    test('denegado para siempre en web no intenta abrir ajustes', () async {
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegadoParaSiempre,
        esWeb: true,
      );
      final ubicacion = UbicacionUsuario(fake);
      addTearDown(ubicacion.dispose);

      await ubicacion.miUbicacion();

      expect(ubicacion.puedeActivar, isFalse);
      expect(ubicacion.mensajeAviso, contains('candado'));
      await ubicacion.activar();
      expect(fake.vecesAjustesApp, 0);
    });

    test('con el GPS apagado abre los ajustes de ubicación', () async {
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.servicioDesactivado,
      );
      final ubicacion = UbicacionUsuario(fake);
      addTearDown(ubicacion.dispose);

      await ubicacion.miUbicacion();
      await ubicacion.activar();

      expect(fake.vecesAjustesUbicacion, 1);
    });

    test('si el servicio falla no se rompe ni muestra el aviso', () async {
      final ubicacion = UbicacionUsuario(_ServicioRoto());
      addTearDown(ubicacion.dispose);

      await ubicacion.iniciar();
      await ubicacion.miUbicacion();

      expect(ubicacion.posicion, isNull);
      expect(ubicacion.mostrarAviso, isFalse);
    });
  });

  group('Mapa de la ruta', () {
    const escritorio = Size(1366, 768);

    testWidgets('"Mi ubicación" pide el permiso, dibuja el marcador azul con '
        'su precisión y centra el mapa', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion();
      await abrirMapa(tester, fake, idRuta: 2);

      expect(botonMiUbicacion, findsOneWidget);
      expect(marcador, findsNothing);

      await tester.tap(botonMiUbicacion);
      await tester.pumpAndSettle();
      fake.emitir(const PosicionUsuario(_piura, 25));
      await tester.pumpAndSettle();

      expect(fake.vecesSolicitado, 1);
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

    testWidgets('si ya hay permiso muestra el marcador sin pedirlo', (
      tester,
    ) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
      );
      await abrirMapa(tester, fake, idRuta: 2);
      fake.emitir(const PosicionUsuario(_piura, 25));
      await tester.pumpAndSettle();

      expect(fake.vecesSolicitado, 0);
      expect(marcador, findsOneWidget);
    });

    testWidgets('si se deniega la app sigue y aparece un aviso discreto', (
      tester,
    ) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      await abrirMapa(tester, fake, idRuta: 2);

      expect(activarUbicacion, findsNothing);
      await tester.tap(botonMiUbicacion);
      await tester.pumpAndSettle();

      expect(activarUbicacion, findsOneWidget);
      expect(find.text('RUTA SELECCIONADA'), findsOneWidget);
      expect(marcador, findsNothing);

      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pumpAndSettle();
      expect(activarUbicacion, findsNothing);
    });

    testWidgets('denegado para siempre en Android: "Activar ubicación" abre '
        'los ajustes de la app', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegadoParaSiempre,
      );
      await abrirMapa(tester, fake, idRuta: 2);
      await tester.tap(botonMiUbicacion);
      await tester.pumpAndSettle();

      await tester.tap(activarUbicacion);
      await tester.pumpAndSettle();

      expect(fake.vecesAjustesApp, 1);
    });

    testWidgets('denegado para siempre en web: explica que se activa desde '
        'el candado', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegadoParaSiempre,
        esWeb: true,
      );
      await abrirMapa(tester, fake, idRuta: 2);
      await tester.tap(botonMiUbicacion);
      await tester.pumpAndSettle();

      expect(find.textContaining('candado'), findsOneWidget);
      expect(activarUbicacion, findsNothing);
      expect(fake.vecesAjustesApp, 0);
    });

    testWidgets('con el GPS apagado "Activar ubicación" abre los ajustes de '
        'ubicación', (tester) async {
      fijarPantalla(tester, escritorio);
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.servicioDesactivado,
      );
      await abrirMapa(tester, fake, idRuta: 2);
      await tester.tap(botonMiUbicacion);
      await tester.pumpAndSettle();

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
      testWidgets('en $nombre, "Mi ubicación" muestra el marcador y centra', (
        tester,
      ) async {
        fijarPantalla(tester, tamano);
        final fake = FakeServicioUbicacion();
        await abrirMapa(tester, fake);

        await tester.tap(botonMiUbicacion);
        await tester.pumpAndSettle();
        fake.emitir(const PosicionUsuario(_piura, 30));
        await tester.pumpAndSettle();

        expect(fake.vecesSolicitado, 1);
        expect(marcador, findsOneWidget);
        expect(centroDelMapa(tester), _piura);
      });
    }

    testWidgets('si se deniega aparece el aviso y el planificador sigue', (
      tester,
    ) async {
      fijarPantalla(tester, const Size(1366, 768));
      final fake = FakeServicioUbicacion(
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      await abrirMapa(tester, fake);
      await tester.tap(botonMiUbicacion);
      await tester.pumpAndSettle();

      expect(activarUbicacion, findsOneWidget);
      expect(find.text('¿A dónde vas?'), findsWidgets);
    });
  });
}
