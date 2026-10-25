import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/data/rutas_repository.dart';
import 'package:piurago/features/viaje/busqueda_viaje.dart';

/// Líneas del Plan Regulador de Rutas (O.M. 092-02-CMPP) que no publica
/// piuratransporta.com: ver docs/datos/rutas-plan-regulador.md.
void main() {
  const repositorio = FakeRutasRepository();

  Future<Ruta> linea(String codigo) async =>
      (await repositorio.listar()).firstWhere((r) => r.codigo == codigo);

  test('hay 24 líneas y ningún código se repite', () async {
    final rutas = await repositorio.listar();
    expect(rutas, hasLength(24));
    expect(rutas.map((r) => r.codigo).toSet(), hasLength(24));
    expect(rutas.map((r) => r.idRuta).toSet(), hasLength(24));
  });

  test('agrega las líneas del plan regulador que faltaban', () async {
    expect((await linea('RD-07')).empresa, '6M Buss SAA');
    expect((await linea('RD-12')).empresa, 'Autogas');
    expect((await linea('RD-13')).empresa, '3W Tours');
    expect((await linea('RD-17')).empresa, 'Rápido Universal');
    for (final codigo in ['RD-07', 'RD-12', 'RD-13', 'RD-17']) {
      final ruta = await linea(codigo);
      expect(ruta.tipoServicio, 'Regulada');
      expect(ruta.frecuenciaMinutos, isNotNull, reason: codigo);
    }
  });

  test('RD-12 y RD-17 tienen paraderos en orden, sin saltos grandes', () async {
    for (final codigo in ['RD-12', 'RD-17']) {
      final paraderos = await repositorio.paraderos(
        (await linea(codigo)).idRuta,
      );
      expect(paraderos.length, greaterThanOrEqualTo(8), reason: codigo);
      for (var i = 1; i < paraderos.length; i++) {
        expect(paraderos[i].ordenSecuencial, i + 1);
        final tramo = distanciaMetros(
          posicionDe(paraderos[i - 1]),
          posicionDe(paraderos[i]),
        );
        expect(tramo, lessThan(3500), reason: '$codigo, paradero ${i + 1}');
      }
    }
  });

  test('las líneas sin recorrido oficial lo dicen y no tienen paraderos', () async {
    for (final codigo in ['RD-07', 'RD-13']) {
      final ruta = await linea(codigo);
      expect(ruta.descripcion, contains('Recorrido pendiente'));
      expect(await repositorio.paraderos(ruta.idRuta), isEmpty);
    }
  });

  test('Planificar viaje ya puede sugerir la RD-12', () async {
    final rutas = await repositorio.listar();
    final paraderos = {
      for (final r in rutas) r.idRuta: await repositorio.paraderos(r.idRuta),
    };
    final rd12 = paraderos[(await linea('RD-12')).idRuta]!;
    final resultado = buscarOpciones(
      origen: posicionDe(rd12[2]),
      destino: const LatLng(-5.18784, -80.62679),
      rutas: rutas,
      paraderos: paraderos,
    );
    expect(resultado.opciones.map((o) => o.ruta.codigo), contains('RD-12'));
  });
}
