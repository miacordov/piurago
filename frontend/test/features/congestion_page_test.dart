import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/app.dart';
import 'package:piurago/core/routes.dart';
import 'package:piurago/core/theme/app_theme.dart';
import 'package:piurago/data/models/resumen_congestion.dart';
import 'package:piurago/data/rutas_repository.dart';
import 'package:piurago/features/congestion/congestion_page.dart';

void fijarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

const resumenMedioDia = ResumenCongestion(
  franjaHoraria: 'MEDIO_DIA',
  diaSemana: 'MAR',
  nivelGeneral: NivelCongestion.media,
  velocidadPromedio: 14.5,
  demoraPromedio: 1.74,
  rutasConDatos: 3,
  puntosCriticos: 9,
  porFranja: [
    FranjaCongestionResumen('MANANA_PICO', NivelCongestion.alta, 8.2),
    FranjaCongestionResumen('MEDIO_DIA', NivelCongestion.media, 14.5),
    FranjaCongestionResumen('TARDE_PICO', null, null),
    FranjaCongestionResumen('NOCHE', NivelCongestion.baja, 27),
  ],
  tramosCriticos: [
    TramoCritico(
      codigoRuta: 'RD-10',
      nombreRuta: 'UPIS San Gabriel Arcángel - Av. Raúl Mata La Cruz',
      desde: 'Open Plaza',
      hasta: 'Instituto Médico Soy Diabético',
      velocidadPromedio: 6,
      nivel: NivelCongestion.alta,
      demoraMinutos: 4,
    ),
    TramoCritico(
      codigoRuta: 'RD-10',
      nombreRuta: 'UPIS San Gabriel Arcángel - Av. Raúl Mata La Cruz',
      desde: 'Instituto Médico Soy Diabético',
      hasta: 'I.E. Nuestra Señora de la Paz',
      velocidadPromedio: 12,
      nivel: NivelCongestion.media,
      demoraMinutos: 3,
    ),
  ],
);

const resumenVacio = ResumenCongestion(
  franjaHoraria: 'NOCHE',
  diaSemana: 'DOM',
  rutasConDatos: 0,
  puntosCriticos: 0,
  porFranja: [],
  tramosCriticos: [],
);

/// Rutas locales con un resumen de congestión de mentira, como el backend.
class RepoConCongestion extends FakeRutasRepository
    implements FuenteCongestion {
  RepoConCongestion(this.respuesta);

  ResumenCongestion? Function(String? franja) respuesta;
  final pedidas = <String?>[];

  @override
  Future<ResumenCongestion?> resumenCongestion({String? franjaHoraria}) async {
    pedidas.add(franjaHoraria);
    return respuesta(franjaHoraria);
  }
}

Future<void> abrir(
  WidgetTester tester,
  RutasRepository repo, {
  List<Object?>? argumentosMapa,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CongestionPage(repository: repo),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.mapa) {
          argumentosMapa?.add(settings.arguments);
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('pantalla del mapa')),
          );
        }
        return null;
      },
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const escritorio = Size(1366, 900);
  const celular = Size(390, 844);

  testWidgets('muestra el nivel y las métricas reales de la franja actual', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    final repo = RepoConCongestion((_) => resumenMedioDia);
    await abrir(tester, repo);

    // "Ahora": el backend decide la franja con su hora.
    expect(repo.pedidas, [null]);
    expect(find.text('Congestión en Piura'), findsOneWidget);
    expect(find.text('Tránsito moderado'), findsOneWidget);
    expect(find.text('14.5 km/h'), findsOneWidget);
    expect(find.text('+1.7 min/km'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.textContaining('3 rutas'), findsOneWidget);
  });

  testWidgets('las barras muestran el nivel de cada franja del día', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, RepoConCongestion((_) => resumenMedioDia));

    expect(find.byKey(const Key('barra-MANANA_PICO')), findsOneWidget);
    expect(find.byKey(const Key('barra-NOCHE')), findsOneWidget);
    // La tarde no tiene datos: su barra lo dice.
    expect(find.byTooltip('Tarde · sin datos todavía'), findsOneWidget);
    expect(
      find.byTooltip('Mañana · Tránsito lento · 8.2 km/h'),
      findsOneWidget,
    );
  });

  testWidgets('lista los tramos críticos reales con su línea y demora', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, RepoConCongestion((_) => resumenMedioDia));

    expect(find.text('TRAMOS CRÍTICOS'), findsOneWidget);
    expect(
      find.text('Open Plaza → Instituto Médico Soy Diabético'),
      findsOneWidget,
    );
    expect(find.textContaining('RD-10'), findsNWidgets(2));
    expect(find.text('+4 min'), findsOneWidget);
    expect(find.text('Congestión Alta'), findsOneWidget);
    expect(find.text('Congestión Media'), findsOneWidget);
    // Ya no hay tramos escritos a mano.
    expect(find.textContaining('Óvalo Bolognesi'), findsNothing);
  });

  testWidgets('al cambiar de pestaña pide la franja al backend', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    final repo = RepoConCongestion((_) => resumenMedioDia);
    await abrir(tester, repo);

    for (final pestana in ['Mañana', 'Mediodía', 'Tarde', 'Noche']) {
      expect(find.text(pestana), findsWidgets);
    }

    await tester.tap(find.byKey(const Key('pestana-TARDE_PICO')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pestana-NOCHE')));
    await tester.pumpAndSettle();

    expect(repo.pedidas, [null, 'TARDE_PICO', 'NOCHE']);
  });

  testWidgets('sin datos todavía lo explica en vez de inventar cifras', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, RepoConCongestion((_) => resumenVacio));

    expect(find.text('Sin datos'), findsOneWidget);
    expect(
      find.textContaining('Todavía no hay viajes compartidos'),
      findsOneWidget,
    );
    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('TRAMOS CRÍTICOS'), findsNothing);
  });

  testWidgets('si el backend no responde ofrece reintentar', (tester) async {
    fijarPantalla(tester, escritorio);
    final repo = RepoConCongestion((_) => null);
    await abrir(tester, repo);

    expect(
      find.textContaining('No pudimos cargar la congestión'),
      findsOneWidget,
    );

    repo.respuesta = (_) => resumenMedioDia;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Tránsito moderado'), findsOneWidget);
  });

  testWidgets('con los datos de prueba avisa que hace falta el servidor', (
    tester,
  ) async {
    fijarPantalla(tester, escritorio);
    await abrir(tester, const FakeRutasRepository());

    expect(find.textContaining('conectada al servidor'), findsOneWidget);
    expect(find.text('TRAMOS CRÍTICOS'), findsNothing);
  });

  testWidgets('"Ver mapa" abre la ruta del tramo', (tester) async {
    fijarPantalla(tester, escritorio);
    final argumentos = <Object?>[];
    final repo = RepoConCongestion((_) => resumenMedioDia);
    await abrir(tester, repo, argumentosMapa: argumentos);

    await tester.tap(find.text('Ver mapa').first);
    await tester.pumpAndSettle();

    final rd10 = (await repo.listar()).firstWhere((r) => r.codigo == 'RD-10');
    expect(argumentos, [rd10.idRuta]);
    expect(find.text('pantalla del mapa'), findsOneWidget);
  });

  testWidgets('la barra lateral permite navegar a Congestión', (tester) async {
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

  testWidgets('se adapta correctamente a pantalla de celular', (tester) async {
    fijarPantalla(tester, celular);
    await abrir(tester, RepoConCongestion((_) => resumenMedioDia));

    expect(find.text('Congestión en Piura'), findsOneWidget);
    expect(find.text('TRAMOS CRÍTICOS'), findsOneWidget);
    expect(find.text('+4 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
