import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/app.dart';
import 'package:piurago/core/routes.dart';
import 'package:piurago/data/models/eta.dart';
import 'package:piurago/data/models/paradero.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/data/rutas_repository.dart';

/// Repositorio con ETA, como el que llama al backend.
class _RepositorioConEta implements RutasRepository, FuenteEta {
  _RepositorioConEta(this.respuesta);

  final Eta? respuesta;
  final pedidos = <int>[];

  @override
  Future<List<Ruta>> listar() async => const [
    Ruta(
      idRuta: 7,
      codigo: 'RD-10',
      nombre: 'Línea de prueba',
      frecuenciaMinutos: 6,
    ),
  ];

  @override
  Future<List<Paradero>> paraderos(int idRuta) async => const [];

  @override
  Future<List<LatLng>> trazado(int idRuta) async => const [];

  @override
  Future<Eta?> eta(int idRuta) async {
    pedidos.add(idRuta);
    return respuesta;
  }

  @override
  bool get esDemostracion => false;
}

Future<void> abrirRuta(WidgetTester tester, RutasRepository repo) async {
  tester.view.physicalSize = const Size(1366, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    PiuraGoApp(rutasRepository: repo, mostrarMapaBase: false),
  );
  await tester.pumpAndSettle();
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushReplacementNamed(AppRoutes.mapa, arguments: 7);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'con ETA simulado muestra la próxima unidad y "Tiempo estimado"',
    (tester) async {
      final repo = _RepositorioConEta(const Eta(minutos: 5, simulado: true));
      await abrirRuta(tester, repo);

      expect(repo.pedidos, [7]);
      expect(find.text('Próxima unidad estimada'), findsOneWidget);
      expect(find.text('~5 min'), findsOneWidget);
      expect(find.text('Tiempo estimado'), findsOneWidget);
    },
  );

  testWidgets('con ETA en vivo no muestra "Tiempo estimado"', (tester) async {
    final repo = _RepositorioConEta(const Eta(minutos: 2, simulado: false));
    await abrirRuta(tester, repo);

    expect(find.text('~2 min'), findsOneWidget);
    expect(find.text('Tiempo estimado'), findsNothing);
  });

  testWidgets('sin ETA sigue mostrando la frecuencia', (tester) async {
    await abrirRuta(tester, _RepositorioConEta(null));

    expect(find.text('Pasa cada ~6 min'), findsOneWidget);
    expect(find.text('Tiempo estimado'), findsNothing);
  });
}
