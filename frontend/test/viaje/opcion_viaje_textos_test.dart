import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/data/models/paradero.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/features/viaje/busqueda_viaje.dart';
import 'package:piurago/features/viaje/opcion_viaje_card.dart';

import 'repositorio_prueba.dart';

OpcionViaje opcion({
  List<String> lugares = const [],
  List<Paradero> intermedios = const [],
}) {
  return OpcionViaje(
    ruta: Ruta(idRuta: 1, nombre: 'Línea', lugaresDestacados: lugares),
    sube: paraderoPrueba(1, 'Norte', -5.2010),
    baja: paraderoPrueba(9, 'Sur', -5.2190),
    metrosSubida: 0,
    metrosBajada: 0,
    paraderosIntermedios: intermedios,
  );
}

void main() {
  test('dice los lugares conocidos por los que pasa la línea', () {
    expect(textoPasaPor(opcion()), isNull);
    expect(
      textoPasaPor(opcion(lugares: ['Mercado Modelo', 'UNP', 'Real Plaza'])),
      'Pasa por Mercado Modelo · UNP · Real Plaza',
    );
  });

  test('cuenta los paraderos del camino y nombra los primeros', () {
    expect(textoParaderosEnElCamino(opcion()), isNull);
    expect(
      textoParaderosEnElCamino(
        opcion(intermedios: [paraderoPrueba(2, 'Centro', -5.21)]),
      ),
      '1 paradero en el camino: Centro',
    );
    expect(
      textoParaderosEnElCamino(
        opcion(
          intermedios: [
            for (var i = 2; i <= 7; i++) paraderoPrueba(i, 'P$i', -5.21),
          ],
        ),
      ),
      '6 paraderos en el camino: P2, P3, P4, P5 y 2 más',
    );
  });
}
