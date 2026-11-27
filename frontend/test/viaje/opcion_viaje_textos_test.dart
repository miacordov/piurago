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

  test('dice qué letrero buscar y avisa si la línea no atiende', () {
    const ruta = Ruta(
      idRuta: 1,
      nombre: 'Línea',
      puntoInicio: 'Piura',
      puntoFinal: 'Catacaos',
      horario: '06:00–21:00',
    );
    final o = OpcionViaje(
      ruta: ruta,
      sube: paraderoPrueba(1, 'Norte', -5.2010),
      baja: paraderoPrueba(2, 'Sur', -5.2190),
      metrosSubida: 0,
      metrosBajada: 0,
      haciaDonde: 'Catacaos',
    );
    expect(textoDireccion(o), 'Toma la que va hacia Catacaos');
    expect(textoFueraDeHorario(o), isNull);

    final cerrada = OpcionViaje(
      ruta: ruta,
      sube: o.sube,
      baja: o.baja,
      metrosSubida: 0,
      metrosBajada: 0,
      fueraDeHorario: true,
    );
    expect(textoDireccion(cerrada), isNull);
    expect(
      textoFueraDeHorario(cerrada),
      'Fuera de horario · atiende 06:00–21:00',
    );
  });
}
