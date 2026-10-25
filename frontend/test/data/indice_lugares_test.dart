import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/data/lugares/indice_lugares.dart';
import 'package:piurago/data/lugares/lugares_piura.dart';
import 'package:piurago/data/models/lugar.dart';

void main() {
  test('IndiceLugares.de arma el índice de una lista una sola vez', () {
    expect(
      identical(IndiceLugares.de(lugaresPiura), IndiceLugares.de(lugaresPiura)),
      isTrue,
    );
  });

  test('unir pone primero el primer índice y salta lo que se excluye', () {
    final paraderos = IndiceLugares(const [
      Lugar('Mercado Modelo', LatLng(1, 1), tipo: TipoLugar.paradero),
    ]);
    final base = IndiceLugares(const [
      Lugar('Mercado Modelo', LatLng(2, 2), detalle: 'Piura'),
      Lugar('Mercado de Castilla', LatLng(3, 3), detalle: 'Castilla, Piura'),
    ]);

    final unido = IndiceLugares.unir(
      paraderos,
      base,
      excluir: (l) => l.nombre == 'Mercado Modelo',
    );

    expect(unido.lugares.map((l) => l.nombre), [
      'Mercado Modelo',
      'Mercado de Castilla',
    ]);
    expect(unido.lugares.first.tipo, TipoLugar.paradero);
    expect(unido.sugerir('mercado').map((l) => l.nombre), [
      'Mercado Modelo',
      'Mercado de Castilla',
    ]);
  });

  test('el descarte rápido no cambia los resultados', () {
    final indice = IndiceLugares.de(lugaresPiura);
    for (final consulta in [
      'jr lima',
      'jir',
      'av sanchez',
      'avenida sanchez cerro',
      'lima jr',
      'urb santa',
      'mercado',
      'grau',
      'ca',
      'a',
    ]) {
      expect(
        indice.sugerir(consulta).map((l) => '${l.nombre}|${l.detalle}'),
        indice
            .sugerirSinDescarte(consulta)
            .map((l) => '${l.nombre}|${l.detalle}'),
        reason: consulta,
      );
    }
  });
}
