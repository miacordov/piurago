import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/core/theme/app_theme.dart';
import 'package:piurago/data/rutas_repository.dart';
import 'package:piurago/features/map/map_page.dart';

void fijarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> abrirMapaConRuta(WidgetTester tester, {int idRuta = 1}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MapPage(
        repository: const FakeRutasRepository(),
        idRuta: idRuta,
        mostrarMapa: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const escritorio = Size(1366, 768);

  testWidgets('el botón Compartir ruta abre el diálogo de confirmación de abordaje', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrirMapaConRuta(tester);

    expect(find.text('Compartir ruta'), findsOneWidget);
    await tester.ensureVisible(find.text('Compartir ruta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartir ruta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('¿Ya estás a bordo'), findsOneWidget);
    expect(find.textContaining('Tu ubicación se compartirá de forma anónima'), findsOneWidget);
    expect(find.text('Sí, confirmar abordaje'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Cancelar cierra el diálogo
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('¿Ya estás a bordo'), findsNothing);
    expect(find.text('Compartir ruta'), findsOneWidget);
  });

  testWidgets('confirmar abordaje activa el panel de viaje en vivo y permite finalizar viaje', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrirMapaConRuta(tester);

    // Abrir confirmación
    await tester.ensureVisible(find.text('Compartir ruta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartir ruta'));
    await tester.pumpAndSettle();

    // Confirmar
    await tester.tap(find.text('Sí, confirmar abordaje'));
    await tester.pumpAndSettle();

    // Ahora está en vivo
    expect(find.text('EN VIVO'), findsOneWidget);
    expect(find.textContaining('Compartiendo tu ubicación'), findsOneWidget);
    expect(find.text('Finalizar viaje'), findsOneWidget);

    // Finalizar viaje
    await tester.ensureVisible(find.text('Finalizar viaje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar viaje'));
    await tester.pumpAndSettle();

    // Diálogo de viaje finalizado
    expect(find.text('Viaje finalizado'), findsOneWidget);
    expect(find.textContaining('Ya no estás compartiendo tu ubicación'), findsOneWidget);
    expect(find.text('Volver al mapa'), findsOneWidget);

    // Volver al mapa restaura el panel normal
    await tester.tap(find.text('Volver al mapa'));
    await tester.pumpAndSettle();

    expect(find.text('Compartir ruta'), findsOneWidget);
  });
}
