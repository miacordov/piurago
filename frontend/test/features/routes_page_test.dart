import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/core/theme/app_theme.dart';
import 'package:piurago/data/models/paradero.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/data/rutas_repository.dart';
import 'package:piurago/features/routes/routes_page.dart';

class _RepositorioConFalla implements RutasRepository {
  @override
  Future<List<Ruta>> listar() async => throw Exception('sin conexión');

  @override
  Future<List<Paradero>> paraderos(int idRuta) async => const <Paradero>[];

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
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const escritorio = Size(1366, 768);
  const celular = Size(390, 844);

  testWidgets('muestra las líneas de prueba y su total', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    expect(find.text('Encuentra tu ruta'), findsOneWidget);
    expect(find.text('Línea 10 · El Moradito'), findsOneWidget);
    expect(find.text('9 líneas'), findsOneWidget);
    expect(find.text('Modo demostración'), findsOneWidget);
  });

  testWidgets('el buscador filtra por zona o paradero', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    await tester.enterText(find.byType(TextField), 'Tacalá');
    await tester.pumpAndSettle();

    expect(find.text('Ruta D · La Guadalupe'), findsOneWidget);
    expect(find.text('Línea 10 · El Moradito'), findsNothing);
    expect(find.text('1 línea'), findsOneWidget);
  });

  testWidgets('avisa cuando no hay resultados', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('No encontramos rutas'), findsOneWidget);
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
    await tester.pump();

    expect(
      find.text('Congestión estará disponible en una próxima versión.'),
      findsOneWidget,
    );
  });
}
