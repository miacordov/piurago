import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/core/routes.dart';
import 'package:piurago/core/theme/app_theme.dart';
import 'package:piurago/data/ubicacion/servicio_ubicacion.dart';
import 'package:piurago/features/location/location_page.dart';

void fijarPantalla(WidgetTester tester) {
  tester.view.physicalSize = const Size(1366, 768);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('pulsar Activar ubicación solicita el permiso a ServicioUbicacion y navega', (tester) async {
    fijarPantalla(tester);
    final fakeUbicacion = FakeServicioUbicacion(
      permisoInicial: EstadoPermisoUbicacion.denegado,
    );

    String? rutaDestino;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        routes: {
          '/': (_) => LocationPage(servicioUbicacion: fakeUbicacion),
          AppRoutes.rutas: (_) {
            rutaDestino = AppRoutes.rutas;
            return const Scaffold(body: Text('Pantalla Rutas'));
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activa tu ubicación'), findsOneWidget);
    expect(fakeUbicacion.vecesSolicitado, 0);

    // Pulsa el botón principal para activar ubicación
    await tester.tap(find.text('Activar ubicación'));
    await tester.pumpAndSettle();

    // Debe haber solicitado el permiso y avanzado a la pantalla de rutas
    expect(fakeUbicacion.vecesSolicitado, 1);
    expect(rutaDestino, AppRoutes.rutas);
  });

  testWidgets('pulsar Continuar sin activar ubicación no solicita permiso y avanza', (tester) async {
    fijarPantalla(tester);
    final fakeUbicacion = FakeServicioUbicacion();

    String? rutaDestino;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        routes: {
          '/': (_) => LocationPage(servicioUbicacion: fakeUbicacion),
          AppRoutes.rutas: (_) {
            rutaDestino = AppRoutes.rutas;
            return const Scaffold(body: Text('Pantalla Rutas'));
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar sin activar ubicación'));
    await tester.pumpAndSettle();

    expect(fakeUbicacion.vecesSolicitado, 0);
    expect(rutaDestino, AppRoutes.rutas);
  });
}
