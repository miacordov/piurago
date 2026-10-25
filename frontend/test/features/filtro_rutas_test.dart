import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/features/routes/filtro_rutas.dart';

const rutas = [
  Ruta(
    idRuta: 1,
    codigo: 'RD-05',
    nombre: 'Los Polvorines - Centro',
    empresa: 'Transportes Grau',
    tipoServicio: 'Regulada',
    lugaresDestacados: ['Mercado Modelo', 'I.E. Nuestra Señora de Fátima'],
  ),
  Ruta(
    idRuta: 2,
    codigo: 'U-03',
    nombre: 'Santa Margarita - Centro',
    tipoServicio: 'Urbana',
    activa: false,
  ),
  Ruta(
    idRuta: 3,
    codigo: 'I-19',
    nombre: 'Piura - Catacaos',
    tipoServicio: 'Interurbana',
    lugaresDestacados: ['Mercado Modelo', 'Open Plaza'],
  ),
  Ruta(
    idRuta: 4,
    codigo: 'U-01',
    nombre: 'Castilla - Centro',
    tipoServicio: 'Urbana',
  ),
];

List<String> codigos(List<RutaFiltrada> lista) =>
    lista.map((r) => r.ruta.codigo!).toList();

void main() {
  test(
    'sin búsqueda ni tipo salen todas, primero las que están en servicio',
    () {
      expect(codigos(filtrarRutas(rutas)), ['RD-05', 'I-19', 'U-01', 'U-03']);
    },
  );

  test('filtra por tipo de servicio', () {
    expect(codigos(filtrarRutas(rutas, tipo: TipoServicio.urbana)), [
      'U-01',
      'U-03',
    ]);
    expect(codigos(filtrarRutas(rutas, tipo: TipoServicio.interurbana)), [
      'I-19',
    ]);
  });

  test('busca sin tildes ni mayúsculas', () {
    expect(codigos(filtrarRutas(rutas, consulta: 'FATIMA')), ['RD-05']);
    expect(codigos(filtrarRutas(rutas, consulta: 'catacaos')), ['I-19']);
  });

  test('el código vale con o sin guion', () {
    expect(codigos(filtrarRutas(rutas, consulta: 'rd05')), ['RD-05']);
    expect(codigos(filtrarRutas(rutas, consulta: 'rd-05')), ['RD-05']);
    expect(codigos(filtrarRutas(rutas, consulta: 'u 01')), ['U-01']);
  });

  test('varias palabras: todas deben estar', () {
    expect(codigos(filtrarRutas(rutas, consulta: 'mercado plaza')), ['I-19']);
    expect(codigos(filtrarRutas(rutas, consulta: 'centro castilla')), ['U-01']);
  });

  test('dice por qué lugar pasa cuando coincide uno', () {
    final resultado = filtrarRutas(rutas, consulta: 'mercado');
    expect(codigos(resultado), ['RD-05', 'I-19']);
    expect(resultado.first.lugarCoincidente, 'Mercado Modelo');
    // Si coincide el nombre de la línea, no hace falta.
    expect(
      filtrarRutas(rutas, consulta: 'polvorines').single.lugarCoincidente,
      isNull,
    );
  });

  test('cuenta las líneas de cada tipo para los filtros', () {
    final cuenta = contarPorTipo(rutas);
    expect(cuenta[null], 4);
    expect(cuenta[TipoServicio.urbana], 2);
    expect(cuenta[TipoServicio.regulada], 1);
    expect(cuenta[TipoServicio.interurbana], 1);
  });
}
