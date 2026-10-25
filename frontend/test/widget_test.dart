import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/app.dart';
import 'package:piurago/data/rutas_repository.dart';

/// Fija el tamaño de la pantalla de prueba (en píxeles lógicos).
void fijarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> abrirApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const PiuraGoApp(rutasRepository: FakeRutasRepository()),
  );
  await tester.pumpAndSettle();
}

void main() {
  const escritorio = Size(1366, 768);
  const celular = Size(390, 844);

  testWidgets('el login muestra el formulario y los accesos', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrirApp(tester);

    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Regístrate aquí'), findsOneWidget);
    expect(find.text('Continuar como pasajero anónimo'), findsOneWidget);
    expect(find.text('Rutas en tiempo real'), findsOneWidget);
  });

  testWidgets('en el celular el login oculta la ilustración', (tester) async {
    fijarPantalla(tester, celular);
    await abrirApp(tester);

    expect(
      find.text('Tu ruta por Piura, más clara y más cerca.'),
      findsOneWidget,
    );
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Rutas en tiempo real'), findsNothing);
  });

  testWidgets('no avanza si el correo o la contraseña son inválidos', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrirApp(tester);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(find.text('Activa tu ubicación'), findsNothing);
  });

  testWidgets('con datos válidos pasa a activar la ubicación', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrirApp(tester);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.first, 'ana@correo.com');
    await tester.enterText(campos.last, '12345678');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Activa tu ubicación'), findsOneWidget);
  });

  testWidgets('el pasajero anónimo llega a la lista de rutas', (tester) async {
    fijarPantalla(tester, escritorio);
    await abrirApp(tester);

    final anonimo = find.text('Continuar como pasajero anónimo');
    await tester.ensureVisible(anonimo);
    await tester.tap(anonimo);
    await tester.pumpAndSettle();
    expect(find.text('Activa tu ubicación'), findsOneWidget);

    await tester.tap(find.text('Continuar sin activar ubicación'));
    await tester.pumpAndSettle();
    expect(find.text('Encuentra tu ruta'), findsOneWidget);
  });
}
