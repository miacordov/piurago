import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/data/rutas_repository.dart';
import 'package:piurago/features/viaje/busqueda_viaje.dart';

/// Rutas con recorrido oficial de la Municipalidad Provincial de Piura (nota
/// del 7/6/2024): trazado por las calles y paraderos sobre ese trazado.
const codigosOficiales = [
  'RD-05', 'RD-10', 'RD-11', 'RD-12', 'RD-14', //
  'RD-16', 'RD-17', 'RD-19', 'RD-20', 'RD-21',
];

/// Distancia de un punto a una línea quebrada, en metros (aproximada).
double distanciaATrazado(LatLng p, List<LatLng> trazado) {
  var mejor = double.infinity;
  for (var i = 1; i < trazado.length; i++) {
    final a = trazado[i - 1];
    final b = trazado[i];
    // Se prueba el segmento en 20 puntos: basta para estas distancias.
    for (var k = 0; k <= 20; k++) {
      final t = k / 20;
      final q = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final d = distanciaMetros(p, q);
      if (d < mejor) mejor = d;
    }
  }
  return mejor;
}

void main() {
  const repositorio = FakeRutasRepository();

  Future<Ruta> linea(String codigo) async =>
      (await repositorio.listar()).firstWhere((r) => r.codigo == codigo);

  for (final codigo in codigosOficiales) {
    test('$codigo: trazado por las calles y paraderos sobre él', () async {
      final ruta = await linea(codigo);
      final trazado = await repositorio.trazado(ruta.idRuta);
      final paraderos = await repositorio.paraderos(ruta.idRuta);

      expect(trazado.length, greaterThan(10), reason: codigo);
      expect(paraderos.length, greaterThanOrEqualTo(5), reason: codigo);
      for (final p in paraderos) {
        expect(
          distanciaATrazado(posicionDe(p), trazado),
          lessThan(250),
          reason: '$codigo: ${p.nombre}',
        );
      }
      // Sin saltos: el trazado sigue calles. Al simplificarlo, una vía
      // recta y larga (como la Vía de Evitamiento) queda con sus dos
      // extremos, por eso se admiten tramos de hasta 3.5 km. Solo la RD-05
      // tiene tramos rurales más largos, en línea recta entre pueblos.
      if (codigo != 'RD-05') {
        for (var i = 1; i < trazado.length; i++) {
          expect(
            distanciaMetros(trazado[i - 1], trazado[i]),
            lessThan(3500),
            reason: '$codigo, punto $i',
          );
        }
      }
      expect(ruta.recorrido, isNotNull, reason: codigo);
    });
  }

  test('las rutas sin recorrido oficial no tienen trazado', () async {
    for (final codigo in ['I-18', 'RD-01', 'RD-02', 'RD-07', 'RD-13']) {
      expect(await repositorio.trazado((await linea(codigo)).idRuta), isEmpty);
    }
  });

  test('empresa y extremos siguen a la Municipalidad', () async {
    expect((await linea('RD-11')).empresa, 'Santo Toribio de Mogrovejo');
    expect((await linea('RD-14')).empresa, 'Nueva Alternativa del Norte');
    final rd21 = await linea('RD-21');
    expect(rd21.puntoInicio, 'Cura Mori');
    expect(rd21.puntoFinal, 'Terminal Satélite (Piura)');
  });
}
