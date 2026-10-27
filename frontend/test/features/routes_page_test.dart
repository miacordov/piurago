import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/app.dart';
import 'package:piurago/core/routes.dart';
import 'package:piurago/core/theme/app_theme.dart';
import 'package:piurago/data/api/auth_service.dart';
import 'package:piurago/data/api/http_rutas_repository.dart';
import 'package:piurago/data/models/eta.dart';
import 'package:piurago/data/models/paradero.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/data/rutas_repository.dart';
import 'package:piurago/features/congestion/congestion_page.dart';
import 'package:piurago/features/routes/routes_page.dart';

class _RepositorioConFalla implements RutasRepository {
  @override
  Future<List<Ruta>> listar() async => throw Exception('sin conexión');

  @override
  Future<List<Paradero>> paraderos(int idRuta) async => const <Paradero>[];

  @override
  Future<List<LatLng>> trazado(int idRuta) async => const <LatLng>[];

  @override
  bool get esDemostracion => false;
}

void fijarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> abrir(WidgetTester tester, RutasRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: RoutesPage(repository: repository),
      routes: {
        AppRoutes.congestion: (_) => const CongestionPage(),
        AppRoutes.mapa: (_) => const Scaffold(body: Text('Mapa')),
      },
    ),
  );
  await tester.pumpAndSettle();
}

/// Repositorio con ETA, como el que llama al backend: la línea 2 tiene un
/// ETA simulado; la 3 está fuera de servicio.
class _RepositorioConEta implements RutasRepository, FuenteEta {
  final pedidos = <int>[];

  @override
  Future<List<Ruta>> listar() async => const [
    Ruta(idRuta: 1, codigo: 'A-01', nombre: 'Línea con ETA en vivo'),
    Ruta(idRuta: 2, codigo: 'B-02', nombre: 'Línea con ETA estimado'),
    Ruta(idRuta: 3, codigo: 'C-03', nombre: 'Línea parada', activa: false),
  ];

  @override
  Future<List<Paradero>> paraderos(int idRuta) async => const [];

  @override
  Future<List<LatLng>> trazado(int idRuta) async => const [];

  @override
  Future<Eta?> eta(int idRuta) async {
    pedidos.add(idRuta);
    return switch (idRuta) {
      1 => const Eta(minutos: 3, simulado: false),
      2 => const Eta(minutos: 7, simulado: true),
      _ => null,
    };
  }

  @override
  bool get esDemostracion => false;
}

void main() {
  const escritorio = Size(1366, 768);
  const celular = Size(390, 844);

  testWidgets('muestra las líneas de Piura en una lista compacta', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    expect(find.text('Encuentra tu ruta'), findsOneWidget);
    expect(find.text('I-18'), findsOneWidget);
    expect(
      find.text('Terminal Satélite (Piura) - Terminal La Unión'),
      findsOneWidget,
    );
    expect(find.text('EMTRUBAPI · Interurbana'), findsOneWidget);
    expect(find.text('S/ 3.00'), findsWidgets);
    expect(find.text('cada ~10 min'), findsWidgets);
    expect(find.text('24 líneas'), findsOneWidget);
    expect(find.text('Modo demostración'), findsOneWidget);
    // Cada línea es una fila baja: caben varias en la pantalla.
    expect(
      tester.getSize(find.byKey(const ValueKey('ruta-1'))).height,
      lessThan(130),
    );
  });

  testWidgets('los filtros por tipo muestran cuántas líneas hay', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    expect(find.text('Todas (24)'), findsOneWidget);
    expect(find.text('Urbanas (4)'), findsOneWidget);
    expect(find.text('Reguladas (17)'), findsOneWidget);
    expect(find.text('Interurbanas (3)'), findsOneWidget);

    await tester.tap(find.text('Interurbanas (3)'));
    await tester.pumpAndSettle();

    expect(find.text('3 líneas'), findsOneWidget);
    expect(find.text('I-18'), findsOneWidget);
    expect(find.text('RD-01'), findsNothing);

    await tester.tap(find.text('Todas (24)'));
    await tester.pumpAndSettle();
    expect(find.text('24 líneas'), findsOneWidget);
  });

  testWidgets('el buscador filtra por código, zona o empresa', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    await tester.enterText(find.byType(TextField), 'chiclayito');
    await tester.pumpAndSettle();

    expect(find.text('A.H. Chiclayito - CP Monte Castillo'), findsOneWidget);
    expect(find.text('I-18'), findsNothing);
    expect(find.text('1 línea'), findsOneWidget);

    // I-19, RD-08 y RD-21 (piuratransporta) y RD-07 (plan regulador).
    await tester.enterText(find.byType(TextField), '6M Buss');
    await tester.pumpAndSettle();
    expect(find.text('4 líneas'), findsOneWidget);

    // El código vale sin guion.
    await tester.enterText(find.byType(TextField), 'rd01');
    await tester.pumpAndSettle();
    expect(find.text('RD-01'), findsOneWidget);
    expect(find.text('1 línea'), findsOneWidget);
  });

  testWidgets('buscar un lugar dice por dónde pasa cada línea', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    await tester.enterText(find.byType(TextField), 'mercado modelo');
    await tester.pumpAndSettle();

    expect(find.text('13 líneas'), findsOneWidget);
    expect(find.text('Pasa por Mercado Modelo'), findsWidgets);

    // Sin tildes también.
    await tester.enterText(find.byType(TextField), 'fatima');
    await tester.pumpAndSettle();
    expect(find.text('No encontramos rutas'), findsNothing);
  });

  testWidgets('Planificar viaje lleva al buscador del mapa', (tester) async {
    fijarPantalla(tester, escritorio);
    await tester.pumpWidget(
      const PiuraGoApp(
        rutasRepository: FakeRutasRepository(),
        mostrarMapaBase: false,
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushReplacementNamed(AppRoutes.rutas);
    await tester.pumpAndSettle();

    expect(find.text('¿No sabes qué línea tomar?'), findsOneWidget);
    await tester.tap(find.text('Planificar viaje'));
    await tester.pumpAndSettle();

    expect(find.text('¿A dónde vas?'), findsOneWidget);
  });

  testWidgets('tocar una línea la abre en el mapa', (tester) async {
    fijarPantalla(tester, escritorio);
    await tester.pumpWidget(
      const PiuraGoApp(
        rutasRepository: FakeRutasRepository(),
        mostrarMapaBase: false,
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushReplacementNamed(AppRoutes.rutas);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ruta-2')));
    await tester.pumpAndSettle();

    expect(find.text('RUTA SELECCIONADA'), findsOneWidget);
    expect(find.text('Piura - Catacaos'), findsOneWidget);
  });

  testWidgets('avisa las líneas fuera de servicio', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    await tester.enterText(find.byType(TextField), 'Granja de Colores');
    await tester.pumpAndSettle();

    expect(find.text('Fuera de servicio'), findsOneWidget);
  });

  testWidgets('avisa cuando no hay resultados', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('No encontramos rutas'), findsOneWidget);
    await tester.tap(find.text('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('24 líneas'), findsOneWidget);
  });

  testWidgets('muestra un error con opción de reintentar', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, _RepositorioConFalla());

    expect(find.text('No pudimos cargar las rutas'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('en el celular se navega con el menú desplegable', (
    tester,
  ) async {
    fijarPantalla(tester, celular);
    await abrir(tester, const FakeRutasRepository());

    expect(find.text('Encuentra tu ruta'), findsOneWidget);
    expect(find.text('Modo demostración'), findsNothing);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Congestión'));
    await tester.pumpAndSettle();

    expect(find.text('Congestión en Piura'), findsOneWidget);
  });

  testWidgets('con backend, cada línea en servicio muestra su próxima unidad', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    final repo = _RepositorioConEta();
    await abrir(tester, repo);

    // Una consulta por línea en servicio, una sola vez.
    expect(repo.pedidos..sort(), [1, 2]);
    final enVivo = find.byKey(const ValueKey('ruta-1'));
    final estimado = find.byKey(const ValueKey('ruta-2'));
    expect(
      find.descendant(of: enVivo, matching: find.text('~3 min')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: enVivo, matching: find.text('Tiempo estimado')),
      findsNothing,
    );
    expect(
      find.descendant(of: estimado, matching: find.text('~7 min')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: estimado, matching: find.text('Tiempo estimado')),
      findsOneWidget,
    );
    expect(find.text('Fuera de servicio'), findsOneWidget);

    // Buscar no vuelve a pedir los ETA.
    await tester.enterText(find.byType(TextField), 'B-02');
    await tester.pumpAndSettle();
    expect(repo.pedidos, hasLength(2));
  });

  testWidgets('en el celular la fila con ETA no se desborda', (tester) async {
    fijarPantalla(tester, celular);
    await abrir(tester, _RepositorioConEta());

    expect(find.text('~7 min'), findsOneWidget);
  });

  group('aviso "Modo demostración"', () {
    testWidgets('no aparece cuando las rutas vienen del backend', (
      tester,
    ) async {
      fijarPantalla(tester, escritorio);
      await abrir(tester, _RepositorioConEta());

      expect(find.text('Línea con ETA en vivo'), findsOneWidget);
      expect(find.text('Modo demostración'), findsNothing);
    });

    testWidgets(
      'aparece si el backend no responde y se usan los datos de prueba',
      (tester) async {
        fijarPantalla(tester, escritorio);
        final caido = MockClient((_) async => http.Response('error', 503));
        final repo = HttpRutasRepository(
          cliente: caido,
          authService: AuthService(cliente: caido)
            ..establecerTokenManualmente('token'),
        );
        await abrir(tester, repo);

        expect(find.text('I-18'), findsOneWidget);
        expect(find.text('Modo demostración'), findsOneWidget);
      },
    );
  });
}
