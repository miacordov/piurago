import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/app.dart';
import 'package:piurago/core/routes.dart';
import 'package:piurago/data/lugares/lugares_piura.dart';
import 'package:piurago/data/models/lugar.dart';

import '../viaje/repositorio_prueba.dart';

void fijarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Abre la app con el repositorio de prueba (sin el mapa real, que necesita
/// internet) y un buscador de lugares falso, y va al mapa. Sin `idRuta` se
/// abre el modo Planificar viaje.
Future<void> irAlMapa(
  WidgetTester tester, {
  RepositorioPrueba? repositorio,
  BuscadorFalso? buscador,
  int? idRuta,
}) async {
  await tester.pumpWidget(
    PiuraGoApp(
      rutasRepository: repositorio ?? RepositorioPrueba(),
      buscadorLugares: buscador ?? BuscadorFalso(),
      mostrarMapaBase: false,
    ),
  );
  await tester.pumpAndSettle();
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushReplacementNamed(AppRoutes.mapa, arguments: idRuta);
  await tester.pumpAndSettle();
}

final campoDesde = find.byKey(const ValueKey('campo-desde'));
final campoHasta = find.byKey(const ValueKey('campo-hasta'));

Finder sugerencia(String nombre) => find.byKey(ValueKey('sugerencia-$nombre'));
Finder frecuente(String nombre) => find.byKey(ValueKey('frecuente-$nombre'));
Finder tarjeta(String linea) => find.byKey(ValueKey('opcion-$linea'));

String textoDe(WidgetTester tester, Finder campo) =>
    tester.widget<TextField>(campo).controller!.text;

/// Hace clic como en Chrome: con el mouse y con cuadros dibujados entre
/// presionar y soltar (si el botón desaparece al presionar, el clic se pierde).
Future<void> clic(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final gesto = await tester.startGesture(
    tester.getCenter(finder),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump(const Duration(milliseconds: 100));
  await gesto.up();
  await tester.pumpAndSettle();
}

Future<void> elegir(
  WidgetTester tester,
  Finder campo,
  String consulta,
  String nombre,
) async {
  await tester.enterText(campo, consulta);
  await tester.pumpAndSettle();
  await clic(tester, sugerencia(nombre));
}

/// Espera los 300 ms tras la última tecla y la respuesta del buscador.
Future<void> esperarBusqueda(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> viajar(WidgetTester tester, String hasta, String desde) async {
  await elegir(tester, campoHasta, hasta, hasta);
  await elegir(tester, campoDesde, desde, desde);
}

void main() {
  const escritorio = Size(1366, 768);
  const celular = Size(390, 844);

  testWidgets('pide primero el destino y ofrece lugares frecuentes', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    expect(find.text('¿A dónde vas?'), findsOneWidget);
    expect(
      tester.getTopLeft(campoHasta).dy,
      lessThan(tester.getTopLeft(campoDesde).dy),
    );
    expect(find.text('Escribe tu destino…'), findsOneWidget);
    expect(find.text('Escribe el punto de partida…'), findsOneWidget);
    expect(find.byTooltip('Intercambiar origen y destino'), findsOneWidget);
    expect(find.byTooltip('Limpiar'), findsOneWidget);
    expect(find.text('Toca el mapa para fijar tu destino.'), findsOneWidget);
    expect(find.text('Destinos rápidos'), findsOneWidget);
    expect(frecuente('Mercado Central'), findsOneWidget);
    // Ya no hace falta un botón para buscar.
    expect(find.text('Buscar ruta'), findsNothing);
    expect(find.text('RUTA SELECCIONADA'), findsNothing);
  });

  testWidgets('escribir "Merc" muestra sugerencias', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    await tester.enterText(campoHasta, 'Merc');
    await tester.pumpAndSettle();

    expect(sugerencia('Mercado Central'), findsOneWidget);
    expect(sugerencia('Mercado Chico'), findsOneWidget);
    expect(sugerencia('Hospital Sur'), findsNothing);
  });

  testWidgets('un clic con el mouse en la sugerencia la elige y pasa al '
      'origen', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    await elegir(tester, campoHasta, 'hosp', 'Hospital Sur');

    expect(textoDe(tester, campoHasta), 'Hospital Sur');
    expect(sugerencia('Hospital Sur'), findsNothing);
    expect(find.text('Toca el mapa para fijar tu origen.'), findsOneWidget);
    expect(tester.widget<TextField>(campoDesde).focusNode!.hasFocus, isTrue);
  });

  testWidgets('con 1 letra salen los lugares con líneas de bus', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    final buscador = BuscadorFalso();
    await irAlMapa(tester, buscador: buscador);

    await tester.enterText(campoHasta, 'h');
    await esperarBusqueda(tester);

    expect(sugerencia('Hospital Sur'), findsOneWidget);
    expect(find.text('Buscando más lugares…'), findsNothing);
    expect(buscador.pedidos, isEmpty);
  });

  testWidgets('desde la 2.ª letra completa la lista con el buscador', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    final buscador = BuscadorFalso();
    buscador.respuestas['hosp'] = Future.value([
      const Lugar(
        'Hospital Regional',
        LatLng(-5.1869, -80.6226),
        detalle: 'Avenida Grau, Piura, Perú',
      ),
      const Lugar('Hospital Rebagliati', LatLng(-12.08, -77.04)),
    ]);
    await irAlMapa(tester, buscador: buscador);

    await tester.enterText(campoHasta, 'hosp');
    await tester.pump();
    expect(find.text('Buscando más lugares…'), findsOneWidget);
    await esperarBusqueda(tester);

    expect(buscador.pedidos, ['hosp']);
    expect(sugerencia('Hospital Sur'), findsOneWidget);
    // Los paraderos van primero.
    expect(
      tester.getTopLeft(sugerencia('Hospital Sur')).dy,
      lessThan(tester.getTopLeft(sugerencia('Hospital Rebagliati')).dy),
    );
    expect(
      sugerencia('Hospital Regional · Avenida Grau, Piura, Perú'),
      findsOneWidget,
    );
    expect(find.text('Avenida Grau, Piura, Perú'), findsOneWidget);
    expect(sugerencia('Hospital Rebagliati'), findsOneWidget);
    expect(
      find.text('Búsqueda de lugares: Photon · © OpenStreetMap contributors'),
      findsOneWidget,
    );
  });

  testWidgets('un clic en otro lugar lo elige; lejos de las líneas avisa', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    final buscador = BuscadorFalso();
    buscador.respuestas['lima'] = Future.value([
      const Lugar('Lima', LatLng(-12.0464, -77.0428), detalle: 'Lima, Perú'),
    ]);
    await irAlMapa(tester, buscador: buscador);

    await tester.enterText(campoHasta, 'lima');
    await esperarBusqueda(tester);
    await clic(tester, sugerencia('Lima · Lima, Perú'));

    expect(textoDe(tester, campoHasta), 'Lima');
    expect(find.text('Buscando más lugares…'), findsNothing);
    expect(tester.widget<TextField>(campoDesde).focusNode!.hasFocus, isTrue);

    await elegir(tester, campoDesde, 'merc', 'Mercado Central');

    expect(find.text('No encontramos una ruta directa'), findsOneWidget);
  });

  testWidgets('un lugar del buscador cerca de una línea da resultados', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    final buscador = BuscadorFalso();
    buscador.respuestas['clinica'] = Future.value([
      const Lugar('Clínica del Sur', LatLng(-5.2185, -80.63)),
    ]);
    await irAlMapa(tester, buscador: buscador);

    await tester.enterText(campoHasta, 'clinica');
    await esperarBusqueda(tester);
    // Con el dedo también se elige.
    await tester.tap(sugerencia('Clínica del Sur'));
    await tester.pumpAndSettle();
    await elegir(tester, campoDesde, 'merc', 'Mercado Central');

    expect(tarjeta('Línea A'), findsOneWidget);
    expect(
      find.text('Baja en Hospital Sur · 56 m a pie (1 min)'),
      findsOneWidget,
    );
  });

  testWidgets('las flechas recorren las sugerencias y Enter elige', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    await tester.enterText(campoHasta, 'merc');
    await esperarBusqueda(tester);
    // Mercado Central, Mercado Chico y luego "Resultado de merc".
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(textoDe(tester, campoHasta), 'Mercado Chico');
  });

  testWidgets('si falla la búsqueda en línea quedan los lugares locales', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester, buscador: BuscadorFalso(fallar: true));

    await tester.enterText(campoHasta, 'merc');
    await esperarBusqueda(tester);

    expect(
      find.text('No pudimos buscar más lugares. Revisa tu conexión.'),
      findsOneWidget,
    );
    expect(sugerencia('Mercado Central'), findsOneWidget);
    await clic(tester, sugerencia('Mercado Central'));
    expect(textoDe(tester, campoHasta), 'Mercado Central');
  });

  testWidgets('con la base de Piura, "jr lima" sugiere la Calle Lima sin red', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await tester.pumpWidget(
      PiuraGoApp(
        rutasRepository: RepositorioPrueba(),
        buscadorLugares: BuscadorFalso(),
        lugaresConocidos: lugaresPiura,
        mostrarMapaBase: false,
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushReplacementNamed(AppRoutes.mapa);
    await tester.pumpAndSettle();

    await tester.enterText(campoHasta, 'jr lima');
    await tester.pump();

    expect(find.text('Calle Lima'), findsWidgets);
    final lima = lugaresPiura.firstWhere((l) => l.nombre == 'Calle Lima');
    await clic(tester, sugerencia('Calle Lima · ${lima.detalle}'));
    expect(textoDe(tester, campoHasta), 'Calle Lima');
  });

  testWidgets('un clic en un lugar frecuente fija el campo activo', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    await clic(tester, frecuente('Hospital Sur'));
    expect(textoDe(tester, campoHasta), 'Hospital Sur');

    await clic(tester, frecuente('Mercado Central'));
    expect(textoDe(tester, campoDesde), 'Mercado Central');
    expect(tarjeta('Línea A'), findsOneWidget);
  });

  testWidgets('Enter elige la primera sugerencia', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    await tester.enterText(campoHasta, 'hosp');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(textoDe(tester, campoHasta), 'Hospital Sur');
  });

  testWidgets('con destino y origen muestra las líneas sin otro clic', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    await viajar(tester, 'Hospital Sur', 'Mercado Central');

    expect(find.text('Línea A'), findsOneWidget);
    expect(find.text('Empresa A · Urbana'), findsOneWidget);
    expect(
      find.text('Sube en Mercado Central · 0 m a pie (0 min)'),
      findsOneWidget,
    );
    expect(
      find.text('Baja en Hospital Sur · 0 m a pie (0 min)'),
      findsOneWidget,
    );
    expect(find.text('S/ 1.50 · cada ~10 min'), findsOneWidget);
    expect(
      find.text('Sube en Mercado Chico · 222 m a pie (3 min)'),
      findsOneWidget,
    );
    // La línea fuera de servicio no aparece.
    expect(find.text('Línea D'), findsNothing);
    expect(
      tester.getTopLeft(tarjeta('Línea A')).dy,
      lessThan(tester.getTopLeft(tarjeta('Línea B')).dy),
    );
    // La mejor línea queda elegida, con su botón para iniciar el viaje.
    expect(
      find.descendant(
        of: tarjeta('Línea A'),
        matching: find.text('Iniciar viaje'),
      ),
      findsOneWidget,
    );
    expect(find.text('Iniciar viaje'), findsOneWidget);
  });

  testWidgets('un clic en otra línea la elige', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);
    await viajar(tester, 'Hospital Sur', 'Mercado Central');

    await clic(tester, find.text('Línea B'));

    expect(
      find.descendant(
        of: tarjeta('Línea B'),
        matching: find.text('Iniciar viaje'),
      ),
      findsOneWidget,
    );
    expect(find.text('Iniciar viaje'), findsOneWidget);
  });

  testWidgets('Iniciar viaje guía paso a paso hasta llegar', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);
    await viajar(tester, 'Hospital Sur', 'Mercado Central');

    await clic(tester, find.text('Iniciar viaje'));

    expect(find.text('Paso 1 de 4'), findsOneWidget);
    expect(find.text('Camina a la parada'), findsOneWidget);
    expect(find.text('Mercado Central · 0 m (0 min)'), findsOneWidget);
    expect(find.text('Salir del viaje'), findsOneWidget);
    expect(campoHasta, findsNothing);

    await clic(tester, find.text('Ya llegué'));
    expect(find.text('Espera el bus A-01'), findsOneWidget);
    expect(find.text('Línea A · pasa cada ~10 min'), findsOneWidget);

    await clic(tester, find.text('Ya subí'));
    expect(find.text('Vas a bordo'), findsOneWidget);
    expect(find.text('Bájate cerca de Hospital Sur'), findsOneWidget);

    await clic(tester, find.text('Ya bajé'));
    expect(find.text('Camina a tu destino'), findsOneWidget);
    expect(find.text('Hospital Sur · 0 m (0 min)'), findsOneWidget);

    await clic(tester, find.text('Ya llegué'));
    expect(find.text('Llegaste'), findsOneWidget);

    await clic(tester, find.text('Listo'));
    expect(campoHasta, findsOneWidget);
    expect(tarjeta('Línea A'), findsOneWidget);
  });

  testWidgets('Salir del viaje vuelve a los resultados', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);
    await viajar(tester, 'Hospital Sur', 'Mercado Central');
    await clic(tester, find.text('Iniciar viaje'));

    await clic(tester, find.text('Salir del viaje'));

    expect(tarjeta('Línea A'), findsOneWidget);
  });

  testWidgets('sin resultados muestra el aviso', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    await viajar(tester, 'Estadio Lejano', 'Plaza Norte');

    expect(find.text('No encontramos una ruta directa'), findsOneWidget);
  });

  testWidgets('a menos de 300 m sugiere ir caminando', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);

    await viajar(tester, 'Mercado Chico', 'Mercado Central');

    expect(find.text('Todo el trayecto es caminando (222 m).'), findsOneWidget);
  });

  testWidgets('intercambiar invierte origen y destino', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);
    await viajar(tester, 'Hospital Sur', 'Mercado Central');

    await clic(tester, find.byTooltip('Intercambiar origen y destino'));

    expect(textoDe(tester, campoHasta), 'Mercado Central');
    expect(textoDe(tester, campoDesde), 'Hospital Sur');
    expect(
      find.text('Sube en Hospital Sur · 0 m a pie (0 min)'),
      findsOneWidget,
    );
  });

  testWidgets('limpiar vacía los campos', (tester) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester);
    await viajar(tester, 'Hospital Sur', 'Mercado Central');

    await clic(tester, find.byTooltip('Limpiar'));

    expect(textoDe(tester, campoDesde), isEmpty);
    expect(textoDe(tester, campoHasta), isEmpty);
    expect(find.text('Línea A'), findsNothing);
    expect(find.text('Destinos rápidos'), findsOneWidget);
  });

  testWidgets('en el celular el panel va debajo del mapa', (tester) async {
    fijarPantalla(tester, celular);
    await irAlMapa(tester);

    expect(find.text('¿A dónde vas?'), findsOneWidget);
    await viajar(tester, 'Hospital Sur', 'Mercado Central');
    expect(find.text('Línea A'), findsOneWidget);

    await clic(tester, find.text('Iniciar viaje'));
    expect(find.text('Camina a la parada'), findsOneWidget);
  });

  testWidgets('si fallan las rutas se puede reintentar', (tester) async {
    fijarPantalla(tester, escritorio);
    final repositorio = RepositorioPrueba(fallarParaderos: true);
    await irAlMapa(tester, repositorio: repositorio);

    expect(find.text('No pudimos cargar las rutas.'), findsOneWidget);

    repositorio.fallarParaderos = false;
    await clic(tester, find.text('Reintentar'));

    expect(campoHasta, findsOneWidget);
  });

  testWidgets('desde el panel de una ruta se pasa a Planificar viaje', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await irAlMapa(tester, idRuta: 2);
    expect(find.text('RUTA SELECCIONADA'), findsOneWidget);

    await clic(tester, find.text('Planificar viaje'));

    expect(find.text('¿A dónde vas?'), findsOneWidget);
    expect(find.text('RUTA SELECCIONADA'), findsNothing);
  });

  testWidgets('la barra lateral "Mapa" abre Planificar viaje', (tester) async {
    fijarPantalla(tester, escritorio);
    await tester.pumpWidget(
      PiuraGoApp(
        rutasRepository: RepositorioPrueba(),
        buscadorLugares: BuscadorFalso(),
        mostrarMapaBase: false,
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushReplacementNamed(AppRoutes.rutas);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    expect(find.text('¿A dónde vas?'), findsOneWidget);
  });
}
