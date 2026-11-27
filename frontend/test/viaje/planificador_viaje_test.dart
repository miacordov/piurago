import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/features/viaje/busqueda_viaje.dart';
import 'package:piurago/features/viaje/planificador_viaje.dart';

import 'package:piurago/data/models/eta.dart';

import 'repositorio_prueba.dart';

Lugar lugar(PlanificadorViaje p, String nombre) =>
    p.catalogo.firstWhere((l) => l.nombre == nombre);

Future<PlanificadorViaje> cargado([RepositorioPrueba? repositorio]) async {
  final planificador = PlanificadorViaje(repositorio ?? RepositorioPrueba());
  await planificador.cargar();
  return planificador;
}

/// Planificador con el viaje Mercado Central -> Hospital Sur ya buscado.
Future<PlanificadorViaje> conResultados() async {
  final planificador = await cargado();
  planificador
    ..fijarDestino(lugar(planificador, 'Hospital Sur'))
    ..fijarOrigen(lugar(planificador, 'Mercado Central'));
  return planificador;
}

void main() {
  test('carga las rutas, el catálogo y los lugares frecuentes', () async {
    final planificador = PlanificadorViaje(RepositorioPrueba());
    expect(planificador.estado, EstadoViaje.cargando);

    await planificador.cargar();

    expect(planificador.estado, EstadoViaje.vacio);
    expect(planificador.catalogo, hasLength(9));
    expect(planificador.frecuentes.first.nombre, 'Mercado Central');
    // Primero se pide el destino.
    expect(planificador.campoActivo, CampoViaje.hasta);
  });

  test('pide los paraderos de cada ruta una sola vez', () async {
    final repositorio = RepositorioPrueba();
    final planificador = await cargado(repositorio);
    await planificador.cargar();
    planificador
      ..fijarDestino(lugar(planificador, 'Hospital Sur'))
      ..fijarOrigen(lugar(planificador, 'Mercado Central'))
      ..intercambiar();

    expect(repositorio.llamadasListar, 1);
    expect(repositorio.llamadasParaderos, {1: 1, 2: 1, 3: 1, 4: 1, 5: 1});
  });

  test('al elegir el destino pasa a pedir el origen', () async {
    final planificador = await cargado();
    var avisos = 0;
    planificador.addListener(() => avisos++);

    planificador.fijarDestino(lugar(planificador, 'Hospital Sur'));

    expect(planificador.destino!.nombre, 'Hospital Sur');
    expect(planificador.campoActivo, CampoViaje.desde);
    expect(planificador.estado, EstadoViaje.vacio);
    expect(avisos, 1);
  });

  test('con origen y destino busca sola y elige la mejor línea', () async {
    final planificador = await conResultados();

    expect(planificador.estado, EstadoViaje.conResultados);
    expect(planificador.opciones.map((o) => o.ruta.nombre), [
      'Línea A',
      'Línea B',
    ]);
    expect(planificador.elegida, same(planificador.opciones.first));
  });

  test('sin resultados', () async {
    final planificador = await cargado();
    planificador
      ..fijarDestino(lugar(planificador, 'Estadio Lejano'))
      ..fijarOrigen(lugar(planificador, 'Plaza Norte'));

    expect(planificador.estado, EstadoViaje.sinResultados);
    expect(planificador.muyCerca, isFalse);
    expect(planificador.elegida, isNull);
  });

  test('a menos de 300 m avisa que se puede ir caminando', () async {
    final planificador = await cargado();
    planificador
      ..fijarDestino(lugar(planificador, 'Mercado Chico'))
      ..fijarOrigen(lugar(planificador, 'Mercado Central'));

    expect(planificador.estado, EstadoViaje.sinResultados);
    expect(planificador.muyCerca, isTrue);
  });

  test('cambiar el origen repite la búsqueda; borrarlo la quita', () async {
    final planificador = await conResultados();

    planificador.fijarOrigen(lugar(planificador, 'Estadio Lejano'));
    expect(planificador.estado, EstadoViaje.sinResultados);

    planificador.fijarOrigen(null);
    expect(planificador.estado, EstadoViaje.vacio);
    expect(planificador.opciones, isEmpty);
    expect(planificador.campoActivo, CampoViaje.desde);
  });

  test('intercambiar invierte Desde y Hasta y repite la búsqueda', () async {
    final planificador = await conResultados();

    planificador.intercambiar();

    expect(planificador.origen!.nombre, 'Hospital Sur');
    expect(planificador.destino!.nombre, 'Mercado Central');
    expect(planificador.estado, EstadoViaje.conResultados);
    expect(planificador.elegida!.sube.nombre, 'Hospital Sur');
  });

  test('limpiar deja todo como al inicio', () async {
    final planificador = await conResultados();
    planificador
      ..iniciarViaje()
      ..limpiar();

    expect(planificador.origen, isNull);
    expect(planificador.destino, isNull);
    expect(planificador.elegida, isNull);
    expect(planificador.opciones, isEmpty);
    expect(planificador.paso, isNull);
    expect(planificador.estado, EstadoViaje.vacio);
    expect(planificador.campoActivo, CampoViaje.hasta);
  });

  test('fijarPunto asigna el punto tocado al campo activo', () async {
    final planificador = await cargado();
    const sur = LatLng(-5.2190, -80.63);
    const norte = LatLng(-5.2010, -80.63);

    planificador.fijarPunto(sur);
    expect(planificador.destino!.nombre, nombrePuntoEnMapa);
    expect(planificador.destino!.posicion, sur);
    expect(planificador.campoActivo, CampoViaje.desde);

    planificador.fijarPunto(norte);
    expect(planificador.origen!.nombre, 'Punto en el mapa');
    expect(planificador.origen!.posicion, norte);
    expect(planificador.estado, EstadoViaje.conResultados);

    planificador
      ..activarCampo(CampoViaje.hasta)
      ..fijarPunto(const LatLng(-5.2200, -80.63));
    expect(planificador.destino!.posicion, const LatLng(-5.2200, -80.63));
    expect(planificador.origen!.posicion, norte);
  });

  test('elegir otra línea cambia la que se muestra', () async {
    final planificador = await conResultados();
    final segunda = planificador.opciones[1];

    planificador.elegir(segunda);

    expect(planificador.elegida, same(segunda));
    expect(planificador.paraderosDe(segunda.ruta.idRuta), hasLength(2));
    expect(planificador.opciones, hasLength(2));
  });

  test('el viaje guía paso a paso hasta llegar', () async {
    final planificador = await conResultados();
    expect(planificador.paso, isNull);

    planificador.iniciarViaje();
    expect(planificador.paso, PasoViaje.caminarAlParadero);
    planificador.avanzarPaso();
    expect(planificador.paso, PasoViaje.esperarBus);
    planificador.avanzarPaso();
    expect(planificador.paso, PasoViaje.aBordo);
    planificador.avanzarPaso();
    expect(planificador.paso, PasoViaje.caminarAlDestino);
    planificador.avanzarPaso();
    expect(planificador.paso, PasoViaje.llegaste);

    planificador.salirDelViaje();
    expect(planificador.paso, isNull);
    expect(planificador.estado, EstadoViaje.conResultados);
  });

  test('sin línea elegida no se puede iniciar el viaje', () async {
    final planificador = await cargado();
    planificador.iniciarViaje();
    expect(planificador.paso, isNull);
  });

  test(
    'si falla el repositorio queda en error y se puede reintentar',
    () async {
      final repositorio = RepositorioPrueba(fallarParaderos: true);
      final planificador = PlanificadorViaje(repositorio);

      await planificador.cargar();
      expect(planificador.estado, EstadoViaje.error);
      expect(planificador.catalogo, isEmpty);

      repositorio.fallarParaderos = false;
      await planificador.reintentar();
      expect(planificador.estado, EstadoViaje.vacio);
      expect(planificador.catalogo, hasLength(9));
    },
  );

  test('se puede viajar a un lugar elegido de "Otros lugares"', () async {
    final planificador = await cargado();
    planificador
      ..fijarDestino(const Lugar('Clínica del Sur', LatLng(-5.2185, -80.63)))
      ..fijarOrigen(lugar(planificador, 'Mercado Central'));

    expect(planificador.estado, EstadoViaje.conResultados);
    expect(planificador.elegida!.baja.nombre, 'Hospital Sur');
  });

  test('un lugar lejos de todas las líneas no tiene resultados', () async {
    final planificador = await cargado();
    planificador
      ..fijarDestino(const Lugar('Lima', LatLng(-12.0464, -77.0428)))
      ..fijarOrigen(lugar(planificador, 'Mercado Central'));

    expect(planificador.estado, EstadoViaje.sinResultados);
    expect(planificador.muyCerca, isFalse);
  });

  const conocidos = [
    Lugar(
      'Calle Lima',
      LatLng(-5.2000, -80.63),
      tipo: TipoLugar.calle,
      detalle: 'Centro, Piura',
    ),
    // Ya es un paradero: no se repite.
    Lugar('Hospital Sur', LatLng(-5.3000, -80.70), detalle: 'Otra zona'),
  ];

  test('suma la base de lugares conocidos sin repetir paraderos', () async {
    final planificador = PlanificadorViaje(
      RepositorioPrueba(),
      lugaresConocidos: conocidos,
    );
    await planificador.cargar();

    expect(planificador.catalogo, hasLength(10));
    expect(planificador.sugerencias('jr lima').map((l) => l.nombre), [
      'Calle Lima',
    ]);
    expect(lugar(planificador, 'Hospital Sur').tipo, TipoLugar.paradero);
  });

  test('al tocar el mapa usa el nombre de la calle más cercana', () async {
    final planificador = PlanificadorViaje(
      RepositorioPrueba(),
      lugaresConocidos: conocidos,
    );
    await planificador.cargar();

    // Unos 33 m de Calle Lima.
    planificador.fijarPunto(const LatLng(-5.2003, -80.63));
    expect(planificador.destino!.nombre, 'Cerca de Calle Lima');
    expect(planificador.destino!.detalle, 'Centro, Piura');
    expect(planificador.destino!.posicion, const LatLng(-5.2003, -80.63));

    // Lejos de toda calle conocida.
    planificador.fijarPunto(const LatLng(-5.2500, -80.70));
    expect(planificador.origen!.nombre, nombrePuntoEnMapa);
  });

  test('sugerencias filtra el catálogo', () async {
    final planificador = await cargado();
    expect(planificador.sugerencias('merc').map((l) => l.nombre), [
      'Mercado Central',
      'Mercado Chico',
    ]);
  });

  group('la ubicación actual como origen', () {
    test('se usa como origen y basta con elegir el destino', () async {
      final p = await cargado();
      final mercado = lugar(p, 'Mercado Central').posicion;

      p.usarUbicacionActual(mercado);

      expect(p.origen?.nombre, nombreUbicacionActual);
      expect(p.origen?.posicion, mercado);
      expect(p.campoActivo, CampoViaje.hasta, reason: 'falta el destino');

      p.fijarDestino(lugar(p, 'Hospital Sur'));
      expect(p.estado, EstadoViaje.conResultados);
    });

    test('sigue al usuario mientras sea el origen', () async {
      final p = await cargado();
      p.usarUbicacionActual(lugar(p, 'Mercado Central').posicion);
      final otro = lugar(p, 'Hospital Sur').posicion;

      p.usarUbicacionActual(otro);

      expect(p.origen?.posicion, otro);
    });

    test('no reemplaza un origen elegido a mano, ni cuando se borra para '
        'escribir otro', () async {
      final p = await cargado();
      final mercado = lugar(p, 'Mercado Central');
      p.fijarOrigen(mercado);

      p.usarUbicacionActual(lugar(p, 'Hospital Sur').posicion);
      expect(p.origen, mercado);

      p.fijarOrigen(null);
      p.usarUbicacionActual(lugar(p, 'Hospital Sur').posicion);
      expect(p.origen, isNull);
    });

    test('limpiar vuelve a usar la ubicación actual como origen', () async {
      final p = await cargado();
      final aqui = lugar(p, 'Mercado Central').posicion;
      p
        ..usarUbicacionActual(aqui)
        ..fijarOrigen(lugar(p, 'Hospital Sur'))
        ..limpiar();

      expect(p.origen?.nombre, nombreUbicacionActual);
      expect(p.origen?.posicion, aqui);
      expect(p.destino, isNull);
    });
  });

  test('pide la próxima unidad solo de las líneas que sirven y la usa como '
      'espera', () async {
    final repositorio = RepositorioConEta({
      1: const Eta(minutos: 3, simulado: false),
    });
    final p = await cargado(repositorio);

    p
      ..fijarDestino(lugar(p, 'Hospital Sur'))
      ..fijarOrigen(lugar(p, 'Mercado Central'));
    await pumpEventQueue();

    final idsOpciones = {for (final o in p.opciones) o.ruta.idRuta};
    expect(repositorio.pedidos.toSet(), idsOpciones);
    final lineaA = p.opciones.firstWhere((o) => o.ruta.idRuta == 1);
    expect(lineaA.minutosEspera, 3);
    expect(lineaA.esperaEnVivo, isTrue);
    expect(p.elegida?.ruta.idRuta, p.opciones.first.ruta.idRuta);

    // Repetir la búsqueda no vuelve a pedir el mismo ETA.
    p.intercambiar();
    p.intercambiar();
    await pumpEventQueue();
    expect(repositorio.pedidos.length, idsOpciones.length);
  });

  test(
    'el GPS no cambia la línea elegida ni corta la guía del viaje',
    () async {
      final p = await cargado();
      final mercado = lugar(p, 'Mercado Central').posicion;
      p
        ..usarUbicacionActual(mercado)
        ..fijarDestino(lugar(p, 'Hospital Sur'));
      final otra = p.opciones.last;
      p
        ..elegir(otra)
        ..iniciarViaje();

      // El pasajero camina unos metros hacia el paradero.
      p.usarUbicacionActual(
        LatLng(mercado.latitude - 0.0003, mercado.longitude),
      );

      expect(p.elegida?.ruta.idRuta, otra.ruta.idRuta);
      expect(p.paso, PasoViaje.caminarAlParadero);
    },
  );

  test('si el ETA falla, se vuelve a pedir en la próxima búsqueda', () async {
    final repositorio = RepositorioConEta(const {})..fallarEta = true;
    final p = await cargado(repositorio);
    p
      ..fijarDestino(lugar(p, 'Hospital Sur'))
      ..fijarOrigen(lugar(p, 'Mercado Central'));
    await pumpEventQueue();
    final primeros = repositorio.pedidos.length;

    repositorio.fallarEta = false;
    p.intercambiar();
    await pumpEventQueue();

    expect(repositorio.pedidos.length, greaterThan(primeros));
  });
}
