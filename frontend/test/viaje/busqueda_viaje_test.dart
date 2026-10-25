import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/data/models/paradero.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/features/viaje/busqueda_viaje.dart';

import 'repositorio_prueba.dart';

Ruta ruta(
  int id,
  String nombre, {
  int? frecuencia,
  double? pasaje,
  bool activa = true,
}) {
  return Ruta(
    idRuta: id,
    nombre: nombre,
    frecuenciaMinutos: frecuencia,
    pasaje: pasaje,
    activa: activa,
  );
}

const origen = LatLng(-5.2000, -80.63);
const destino = LatLng(-5.2200, -80.63);

ResultadoBusqueda buscar(
  List<Ruta> rutas,
  Map<int, List<Paradero>> paraderos, {
  LatLng desde = origen,
  LatLng hasta = destino,
}) {
  return buscarOpciones(
    origen: desde,
    destino: hasta,
    rutas: rutas,
    paraderos: paraderos,
  );
}

void main() {
  group('distanciaMetros (Haversine)', () {
    test('un grado sobre el ecuador mide unos 111 195 m', () {
      expect(
        distanciaMetros(const LatLng(0, 0), const LatLng(0, 1)),
        closeTo(111194.93, 0.5),
      );
      expect(
        distanciaMetros(const LatLng(0, 0), const LatLng(1, 0)),
        closeTo(111194.93, 0.5),
      );
    });

    test('del ecuador al polo hay un cuarto de meridiano', () {
      expect(
        distanciaMetros(const LatLng(0, 0), const LatLng(90, 0)),
        closeTo(10007543.4, 1),
      );
    });

    test('es simétrica y vale 0 para el mismo punto', () {
      const a = LatLng(-5.1945, -80.6328);
      const b = LatLng(-5.2010, -80.6300);
      expect(distanciaMetros(a, a), 0);
      expect(distanciaMetros(a, b), closeTo(distanciaMetros(b, a), 1e-9));
    });

    test('0.001° de latitud en Piura son unos 111 m', () {
      expect(
        distanciaMetros(origen, const LatLng(-5.2010, -80.63)),
        closeTo(111.19, 0.05),
      );
    });
  });

  test('minutosAPie redondea hacia arriba a 80 m por minuto', () {
    expect(velocidadCaminataMetrosPorMinuto, 80);
    expect(minutosAPie(0), 0);
    expect(minutosAPie(80), 1);
    expect(minutosAPie(81), 2);
    expect(minutosAPie(400), 5);
    expect(minutosAPie(400.5), 6);
  });

  test('paraderoMasCercano elige el de menor distancia', () {
    final lista = [
      paraderoPrueba(1, 'Lejos', -5.2100),
      paraderoPrueba(2, 'Cerca', -5.2010),
      paraderoPrueba(3, 'Medio', -5.2050),
    ];
    expect(paraderoMasCercano(lista, origen).nombre, 'Cerca');
  });

  group('buscarOpciones', () {
    test('una ruta con paraderos cerca de ambos puntos es candidata', () {
      final r = ruta(1, 'Línea 1');
      final resultado = buscar(
        [r],
        {
          1: [
            paraderoPrueba(1, 'Norte', -5.2010),
            paraderoPrueba(2, 'Sur', -5.2190),
          ],
        },
      );

      expect(resultado.muyCerca, isFalse);
      expect(resultado.opciones, hasLength(1));
      final opcion = resultado.opciones.single;
      expect(opcion.ruta, same(r));
      expect(opcion.sube.nombre, 'Norte');
      expect(opcion.baja.nombre, 'Sur');
      expect(opcion.metrosSubida, closeTo(111.19, 0.05));
      expect(opcion.metrosBajada, closeTo(111.19, 0.05));
      expect(opcion.metrosTotales, closeTo(222.39, 0.1));
      expect(opcion.minutosSubida, 2);
      expect(opcion.minutosBajada, 2);
    });

    test('excluye la ruta si una caminata pasa de 600 m', () {
      expect(caminataMaximaMetros, 600);
      final resultado = buscar(
        [ruta(1, 'Dentro'), ruta(2, 'Fuera')],
        {
          // Unos 589 m al subir: entra.
          1: [
            paraderoPrueba(1, 'Norte', -5.2053),
            paraderoPrueba(2, 'Sur', -5.2200),
          ],
          // Unos 612 m al subir: queda fuera.
          2: [
            paraderoPrueba(3, 'Norte', -5.2055),
            paraderoPrueba(4, 'Sur', -5.2200),
          ],
        },
      );
      expect(resultado.opciones.map((o) => o.ruta.nombre), ['Dentro']);
    });

    test('excluye la ruta si sube y baja en el mismo paradero', () {
      final resultado = buscar(
        [ruta(1, 'Un solo lado')],
        {
          1: [
            paraderoPrueba(1, 'Centro', -5.2100),
            paraderoPrueba(2, 'Muy lejos', -5.3000),
          ],
        },
        desde: const LatLng(-5.2070, -80.63),
        hasta: const LatLng(-5.2130, -80.63),
      );
      expect(resultado.muyCerca, isFalse);
      expect(resultado.opciones, isEmpty);
    });

    test('ignora las rutas con menos de 2 paraderos', () {
      final resultado = buscar(
        [ruta(1, 'Uno'), ruta(2, 'Ninguno')],
        {
          1: [paraderoPrueba(1, 'Solo', -5.2000)],
        },
      );
      expect(resultado.opciones, isEmpty);
    });

    test('excluye las rutas fuera de servicio', () {
      final resultado = buscar(
        [ruta(1, 'Activa'), ruta(2, 'Inactiva', activa: false)],
        {
          1: [
            paraderoPrueba(1, 'Norte', -5.2010),
            paraderoPrueba(2, 'Sur', -5.2190),
          ],
          2: [
            paraderoPrueba(3, 'Norte', -5.2000),
            paraderoPrueba(4, 'Sur', -5.2200),
          ],
        },
      );
      expect(resultado.opciones.map((o) => o.ruta.nombre), ['Activa']);
    });

    test('ordena por caminata total, de menor a mayor', () {
      final resultado = buscar(
        [ruta(1, 'Lejos'), ruta(2, 'Cerca'), ruta(3, 'Medio')],
        {
          1: [paraderoPrueba(1, 'N', -5.2030), paraderoPrueba(2, 'S', -5.2170)],
          2: [paraderoPrueba(3, 'N', -5.2005), paraderoPrueba(4, 'S', -5.2195)],
          3: [paraderoPrueba(5, 'N', -5.2010), paraderoPrueba(6, 'S', -5.2190)],
        },
      );
      expect(resultado.opciones.map((o) => o.ruta.nombre), [
        'Cerca',
        'Medio',
        'Lejos',
      ]);
    });

    Map<int, List<Paradero>> mismosParaderos(List<int> ids) => {
      for (final id in ids)
        id: [
          paraderoPrueba(id * 10, 'N', -5.2010),
          paraderoPrueba(id * 10 + 1, 'S', -5.2190),
        ],
    };

    test('con igual caminata desempata por frecuencia, nulos al final', () {
      final resultado = buscar([
        ruta(1, 'Cada 10', frecuencia: 10),
        ruta(2, 'Sin dato'),
        ruta(3, 'Cada 5', frecuencia: 5),
      ], mismosParaderos([1, 2, 3]));
      expect(resultado.opciones.map((o) => o.ruta.nombre), [
        'Cada 5',
        'Cada 10',
        'Sin dato',
      ]);
    });

    test('luego desempata por pasaje, nulos al final', () {
      final resultado = buscar([
        ruta(1, 'Sin pasaje', frecuencia: 10),
        ruta(2, 'Dos soles', frecuencia: 10, pasaje: 2.0),
        ruta(3, 'Un sol', frecuencia: 10, pasaje: 1.0),
      ], mismosParaderos([1, 2, 3]));
      expect(resultado.opciones.map((o) => o.ruta.nombre), [
        'Un sol',
        'Dos soles',
        'Sin pasaje',
      ]);
    });

    test('y al final por nombre', () {
      final resultado = buscar([
        ruta(1, 'Zeta', frecuencia: 10, pasaje: 1.0),
        ruta(2, 'Alfa', frecuencia: 10, pasaje: 1.0),
      ], mismosParaderos([1, 2]));
      expect(resultado.opciones.map((o) => o.ruta.nombre), ['Alfa', 'Zeta']);
    });

    test('a menos de 300 m no busca rutas: se puede ir caminando', () {
      expect(distanciaParaCaminarMetros, 300);
      final resultado = buscar(
        [ruta(1, 'Corta')],
        {
          1: [paraderoPrueba(1, 'N', -5.2000), paraderoPrueba(2, 'S', -5.2020)],
        },
        hasta: const LatLng(-5.2020, -80.63),
      );
      expect(resultado.muyCerca, isTrue);
      expect(resultado.opciones, isEmpty);
    });

    test('sin rutas el resultado está vacío', () {
      final resultado = buscar(const [], const {});
      expect(resultado.muyCerca, isFalse);
      expect(resultado.opciones, isEmpty);
    });

    test('la opción expone los datos de servicio de la ruta', () {
      final resultado = buscar(rutasPrueba, paraderosPrueba);
      final opcion = resultado.opciones.first;
      expect(opcion.ruta.nombre, 'Línea A');
      expect(opcion.pasaje, 1.50);
      expect(opcion.frecuenciaMinutos, 10);
      expect(opcion.empresa, 'Empresa A');
      expect(opcion.tipoServicio, 'Urbana');
    });
  });

  group('catálogo de lugares', () {
    test('une nombres sin distinguir mayúsculas ni tildes', () {
      final catalogo = construirCatalogo(
        [ruta(1, 'Uno'), ruta(2, 'Dos')],
        {
          1: [
            paraderoPrueba(1, 'Plaza de Fátima', -5.20),
            paraderoPrueba(2, 'Mercado Modelo', -5.21),
          ],
          2: [
            paraderoPrueba(3, 'MERCADO MODELO', -5.25),
            paraderoPrueba(4, 'plaza de fatima', -5.26),
          ],
        },
      );
      expect(catalogo.map((l) => l.nombre), [
        'Plaza de Fátima',
        'Mercado Modelo',
      ]);
      // Si se repite el nombre, se usa la coordenada del primero.
      expect(catalogo[1].posicion, const LatLng(-5.21, -80.63));
    });

    test('con los datos de prueba hay 9 lugares', () {
      expect(construirCatalogo(rutasPrueba, paraderosPrueba), hasLength(9));
    });

    test('lugares frecuentes: los que tienen más líneas activas, hasta 6', () {
      final populares = lugaresFrecuentes(rutasPrueba, paraderosPrueba);
      expect(populares.map((l) => l.nombre), [
        // Pasan 2 líneas; el resto, 1 (en el orden en que aparecen).
        'Mercado Central',
        'Plaza Norte',
        'Hospital Sur',
        'Mercado Chico',
        'Colegio Sur',
        'Estadio Lejano',
      ]);
      // Usa la coordenada del primer paradero con ese nombre.
      expect(populares.first.posicion, const LatLng(-5.2010, -80.63));
      // Los lugares de líneas fuera de servicio no se sugieren.
      expect(populares.map((l) => l.nombre), isNot(contains('Terminal Norte')));
    });

    test('sugerencias: contiene, sin tildes ni mayúsculas', () {
      final catalogo = [
        const Lugar('Mercado Modelo', LatLng(0, 0)),
        const Lugar('I.E. Fátima', LatLng(0, 0)),
        const Lugar('Supermercado', LatLng(0, 0)),
      ];
      expect(sugerirLugares(catalogo, 'merc').map((l) => l.nombre), [
        'Mercado Modelo',
        'Supermercado',
      ]);
      expect(
        sugerirLugares(catalogo, 'MODELO').single.nombre,
        'Mercado Modelo',
      );
      expect(sugerirLugares(catalogo, 'fatima').single.nombre, 'I.E. Fátima');
      expect(sugerirLugares(catalogo, '  '), isEmpty);
    });

    test('sugerencias: entiende las abreviaturas de calles', () {
      final catalogo = [
        const Lugar('Jirón Lima', LatLng(0, 0), tipo: TipoLugar.calle),
        const Lugar('Avenida Grau', LatLng(0, 0), tipo: TipoLugar.calle),
        const Lugar('Av. Sánchez Cerro', LatLng(0, 0), tipo: TipoLugar.calle),
        const Lugar('Pasaje Los Olivos', LatLng(0, 0), tipo: TipoLugar.calle),
        const Lugar(
          'Urbanización Santa Ana',
          LatLng(0, 0),
          tipo: TipoLugar.zona,
        ),
      ];
      List<String> nombres(String q) =>
          sugerirLugares(catalogo, q).map((l) => l.nombre).toList();

      expect(nombres('jr'), ['Jirón Lima']);
      expect(nombres('jr. lim'), ['Jirón Lima']);
      expect(nombres('jir'), ['Jirón Lima']);
      expect(nombres('av grau'), ['Avenida Grau']);
      expect(nombres('avenida sanchez'), ['Av. Sánchez Cerro']);
      expect(nombres('av'), ['Avenida Grau', 'Av. Sánchez Cerro']);
      expect(nombres('psje olivos'), ['Pasaje Los Olivos']);
      expect(nombres('urb santa'), ['Urbanización Santa Ana']);
      // Cada palabra puede ir en cualquier parte del nombre.
      expect(nombres('lima jr'), ['Jirón Lima']);
    });

    test('sugerencias: "jr", "jirón" y "calle" son lo mismo', () {
      // En OpenStreetMap el Jr. Lima del centro de Piura es "Calle Lima".
      final catalogo = [
        const Lugar('Calle Lima', LatLng(0, 0), tipo: TipoLugar.calle),
        const Lugar('Jirón Tacna', LatLng(0, 0), tipo: TipoLugar.calle),
        const Lugar('Avenida Lima', LatLng(0, 0), tipo: TipoLugar.calle),
      ];
      List<String> nombres(String q) =>
          sugerirLugares(catalogo, q).map((l) => l.nombre).toList();

      expect(nombres('jr lima'), ['Calle Lima']);
      expect(nombres('jirón lima'), ['Calle Lima']);
      expect(nombres('calle tacna'), ['Jirón Tacna']);
      expect(nombres('ca tacna'), ['Jirón Tacna']);
      expect(nombres('av lima'), ['Avenida Lima']);
      // Sin tipo de vía salen todas las que tienen ese nombre.
      expect(nombres('lima'), ['Calle Lima', 'Avenida Lima']);
    });

    test('sugerencias: primero las que empiezan con lo escrito', () {
      final catalogo = [
        const Lugar('Colegio San Miguel', LatLng(0, 0)),
        const Lugar('Calle San Miguel', LatLng(0, 0), tipo: TipoLugar.calle),
        const Lugar('San Miguel de Piura', LatLng(0, 0)),
      ];
      expect(sugerirLugares(catalogo, 'san mig').map((l) => l.nombre), [
        'San Miguel de Piura',
        'Colegio San Miguel',
        'Calle San Miguel',
      ]);
    });

    test('el catálogo de paraderos marca sus lugares como paraderos', () {
      final catalogo = construirCatalogo(rutasPrueba, paraderosPrueba);
      expect(catalogo.every((l) => l.tipo == TipoLugar.paradero), isTrue);
    });

    test('sugerencias: como máximo 5, como piuratransporta', () {
      final catalogo = [
        for (var i = 0; i < 9; i++) Lugar('Paradero $i', const LatLng(0, 0)),
      ];
      expect(maximoSugerencias, 5);
      expect(sugerirLugares(catalogo, 'parad'), hasLength(5));
    });
  });

  test('puntosCasiIguales decide si basta centrar el mapa', () {
    expect(puntosCasiIguales(const [origen]), isTrue);
    expect(puntosCasiIguales(const [origen, LatLng(-5.20005, -80.63)]), isTrue);
    expect(puntosCasiIguales(const [origen, destino]), isFalse);
  });
}
