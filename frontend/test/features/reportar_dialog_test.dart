import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/core/theme/app_theme.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/data/rutas_repository.dart';
import 'package:piurago/features/reportes/reportar_dialog.dart';

class _FuenteFalsa implements FuenteReportes {
  _FuenteFalsa({this.responde = true});

  final bool responde;
  final enviados = <NuevoReporte>[];

  @override
  Future<bool> reportar(NuevoReporte reporte) async {
    enviados.add(reporte);
    return responde;
  }
}

const _rutas = [
  Ruta(idRuta: 1, codigo: 'RD-07', nombre: 'Castilla - Veintiséis de Octubre'),
  Ruta(idRuta: 2, codigo: 'U-03', nombre: 'Santa Margarita - Centro'),
];
const _aqui = LatLng(-5.19, -80.63);

Future<void> abrir(
  WidgetTester tester, {
  FuenteReportes? fuente,
  int? idRuta,
  LatLng? ubicacion,
}) async {
  tester.view.physicalSize = const Size(1366, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => mostrarReportarDialog(
              context,
              rutas: _rutas,
              fuente: fuente,
              idRuta: idRuta,
              ubicacion: ubicacion,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

final campoDescripcion = find.byKey(const ValueKey('reporte-descripcion'));

void main() {
  testWidgets('pide describir qué cambió antes de enviar', (tester) async {
    final fuente = _FuenteFalsa();
    await abrir(tester, fuente: fuente);

    expect(find.text('Reportar un cambio'), findsOneWidget);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Describe qué cambió'), findsOneWidget);
    expect(fuente.enviados, isEmpty);
  });

  testWidgets('envía el tipo, la línea, la descripción y, si se elige, la '
      'ubicación', (tester) async {
    final fuente = _FuenteFalsa();
    await abrir(tester, fuente: fuente, idRuta: 2, ubicacion: _aqui);

    await tester.tap(find.text('Hay un paradero nuevo'));
    await tester.enterText(campoDescripcion, '  Frente al mercado  ');
    // La ubicación se comparte solo si el pasajero lo elige.
    await tester.tap(find.text('Incluir mi ubicación'));
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    final enviado = fuente.enviados.single;
    expect(enviado.tipo, TipoReporte.paraderoNuevo);
    expect(enviado.idRuta, 2);
    expect(enviado.descripcion, 'Frente al mercado');
    expect(enviado.ubicacion, _aqui);
    expect(find.text('Reportar un cambio'), findsNothing);
    expect(find.text('¡Gracias! Lo revisaremos.'), findsOneWidget);
  });

  testWidgets('sin elegirla, la ubicación no se envía', (tester) async {
    final fuente = _FuenteFalsa();
    await abrir(tester, fuente: fuente, ubicacion: _aqui);

    await tester.enterText(campoDescripcion, 'Cambió el recorrido');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(fuente.enviados.single.ubicacion, isNull);
    expect(fuente.enviados.single.tipo, TipoReporte.rutaCambio);
  });

  testWidgets('sin GPS no ofrece incluir la ubicación', (tester) async {
    await abrir(tester, fuente: _FuenteFalsa());
    expect(find.text('Incluir mi ubicación'), findsNothing);
  });

  testWidgets('si el envío falla lo dice y deja reintentar', (tester) async {
    await abrir(tester, fuente: _FuenteFalsa(responde: false));

    await tester.enterText(campoDescripcion, 'Cambió el recorrido');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos enviar el reporte. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Reportar un cambio'), findsOneWidget);
  });

  testWidgets('en modo demostración avisa que no se envía', (tester) async {
    await abrir(tester);

    expect(
      find.text('Sin conexión con el servidor: el reporte no se puede enviar.'),
      findsOneWidget,
    );
    final enviar = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enviar'),
    );
    expect(enviar.onPressed, isNull);
  });
}
