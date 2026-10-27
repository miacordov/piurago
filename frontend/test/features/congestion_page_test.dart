import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/app.dart';
import 'package:piurago/core/theme/app_theme.dart';
import 'package:piurago/features/congestion/congestion_page.dart';

void fijarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> abrir(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const CongestionPage(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const escritorio = Size(1366, 768);
  const celular = Size(390, 844);

  testWidgets('muestra el encabezado y el estado general de congestión', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester);

    expect(find.text('ESTADO DEL TRÁNSITO'), findsOneWidget);
    expect(find.text('Congestión en Piura'), findsOneWidget);
    expect(find.text('Demora promedio'), findsOneWidget);
    expect(find.text('Velocidad promedio'), findsOneWidget);
    expect(find.text('Puntos críticos'), findsOneWidget);
  });

  testWidgets('permite cambiar entre las pestañas de franjas horarias', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester);

    expect(find.text('Ahora'), findsOneWidget);
    expect(find.text('Mañana'), findsOneWidget);
    expect(find.text('Tarde'), findsOneWidget);
    expect(find.text('Noche'), findsOneWidget);

    await tester.tap(find.text('Tarde'));
    await tester.pumpAndSettle();

    // Sigue mostrando las secciones tras cambiar de pestaña
    expect(find.text('TRAMOS CRÍTICOS'), findsOneWidget);
  });

  testWidgets('muestra la lista de tramos críticos de Piura', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester);

    expect(find.text('TRAMOS CRÍTICOS'), findsOneWidget);
    expect(find.textContaining('Óvalo Bolognesi'), findsOneWidget);
    expect(find.textContaining('Mercado Modelo'), findsOneWidget);
  });

  testWidgets('la barra lateral permite navegar a Congestión', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await tester.pumpWidget(const PiuraGoApp());
    await tester.pumpAndSettle();

    // Desde login entrar como anónimo
    await tester.tap(find.text('Continuar como pasajero anónimo'));
    await tester.pumpAndSettle();

    // Saltar pantalla de ubicación
    await tester.tap(find.text('Continuar sin activar ubicación'));
    await tester.pumpAndSettle();

    // En la barra lateral tocar "Congestión"
    await tester.tap(find.text('Congestión'));
    await tester.pumpAndSettle();

    expect(find.text('Congestión en Piura'), findsOneWidget);
  });

  testWidgets('se adapta correctamente a pantalla de celular', (
    tester,
  ) async {
    fijarPantalla(tester, celular);
    await abrir(tester);

    expect(find.text('Congestión en Piura'), findsOneWidget);
    expect(find.text('TRAMOS CRÍTICOS'), findsOneWidget);
  });
}
