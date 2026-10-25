import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/app.dart';
import 'package:piurago/core/routes.dart';
import 'package:piurago/data/models/paradero.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/data/rutas_repository.dart';

class _RepositorioSinParaderos implements RutasRepository {
  const _RepositorioSinParaderos();

  @override
  Future<List<Ruta>> listar() async => const [Ruta(idRuta: 1, nombre: 'Ruta')];

  @override
  Future<List<Paradero>> paraderos(int idRuta) async => const <Paradero>[];

  @override
  bool get esDemostracion => true;
}

void fijarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Abre la app (sin el mapa real, que necesita internet) y va a una pantalla.
Future<NavigatorState> abrirApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const PiuraGoApp(
      rutasRepository: FakeRutasRepository(),
      mostrarMapaBase: false,
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<NavigatorState>(find.byType(Navigator).first);
}

Future<void> irAlMapa(WidgetTester tester, {int? idRuta}) async {
  final navegador = await abrirApp(tester);
  navegador.pushReplacementNamed(AppRoutes.mapa, arguments: idRuta);
  await tester.pumpAndSettle();
}

void main() {
  const escritorio = Size(1366, 768);
  const celular = Size(390, 844);

  testWidgets('el mapa muestra el panel de la ruta seleccionada', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester, idRuta: 2);

    expect(find.text('RUTA SELECCIONADA'), findsOneWidget);
    expect(find.text('Piura - Catacaos'), findsOneWidget);
    expect(
      find.text('I-19 · 6M Buss SAA · Interurbana\nPiura → Catacaos'),
      findsOneWidget,
    );
    expect(find.text('Pasa cada ~15 min'), findsOneWidget);
    expect(
      find.text('05:30–22:00 · S/ 3.00 · Estudiante S/ 1.50'),
      findsOneWidget,
    );
    expect(find.text('Paraderos de la ruta'), findsOneWidget);
    expect(find.text('10 paraderos'), findsOneWidget);
    expect(find.text('Gobierno Regional'), findsWidgets);
    expect(find.text('Lugares por los que pasa'), findsOneWidget);
    expect(find.text('Compartir ruta'), findsOneWidget);
    expect(find.text('Marcar como superada'), findsOneWidget);
  });

  testWidgets('una ruta sin paraderos avisa que faltan datos', (tester) async {
    fijarPantalla(tester, escritorio);
    await tester.pumpWidget(
      const PiuraGoApp(
        rutasRepository: _RepositorioSinParaderos(),
        mostrarMapaBase: false,
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushReplacementNamed(AppRoutes.mapa, arguments: 1);
    await tester.pumpAndSettle();

    expect(
      find.text('Esta ruta todavía no tiene paraderos cargados.'),
      findsOneWidget,
    );
  });

  testWidgets('sin ruta indicada abre Planificar viaje', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    expect(find.text('¿A dónde vas?'), findsOneWidget);
    expect(find.text('RUTA SELECCIONADA'), findsNothing);
  });

  testWidgets('tocar una línea en Rutas abre la ruta elegida', (tester) async {
    fijarPantalla(tester, escritorio);
    final navegador = await abrirApp(tester);
    navegador.pushReplacementNamed(AppRoutes.rutas);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ruta-2')));
    await tester.pumpAndSettle();

    expect(find.text('RUTA SELECCIONADA'), findsOneWidget);
    expect(find.text('Piura - Catacaos'), findsOneWidget);
  });

  testWidgets('la barra lateral lleva del mapa a las rutas', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester, idRuta: 1);

    await tester.tap(find.text('Rutas'));
    await tester.pumpAndSettle();

    expect(find.text('Encuentra tu ruta'), findsOneWidget);
  });

  testWidgets('en el celular el mapa y el panel se apilan', (tester) async {
    fijarPantalla(tester, celular);
    await irAlMapa(tester, idRuta: 1);

    expect(find.text('RUTA SELECCIONADA'), findsOneWidget);
    expect(
      find.text('Terminal Satélite (Piura) - Terminal La Unión'),
      findsOneWidget,
    );
  });
}
