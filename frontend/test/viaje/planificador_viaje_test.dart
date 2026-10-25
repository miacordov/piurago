import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/features/viaje/busqueda_viaje.dart';
import 'package:piurago/features/viaje/planificador_viaje.dart';

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

  test('sugerencias filtra el catálogo', () async {
    final planificador = await cargado();
    expect(planificador.sugerencias('merc').map((l) => l.nombre), [
      'Mercado Central',
      'Mercado Chico',
    ]);
  });
}
