import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/data/models/ruta.dart';

void main() {
  // Respuesta con la forma de GET /api/rutas del backend.
  final json = <String, dynamic>{
    'idRuta': 1,
    'codigo': 'RD-11',
    'nombre': 'RD-11 Los Almendros – Aguilar Santisteban',
    'empresa':
        'Empresa de Transportes y Servicios Santo Toribio de Mogrovejo SAC',
    'puntoInicio': 'A.H. Los Almendros',
    'puntoFinal': 'Av. José Aguilar Santisteban',
    'sentido': 'IDA_VUELTA',
    'descripcion': 'A.H. Los Almendros ↔ Av. José Aguilar Santisteban',
    'recorrido': 'Vía del Mercado → Av. Los Almendros',
    'activa': true,
    'tiempoEstimado': null,
    'frecuenciaMinutos': null,
  };

  test('fromJson lee la respuesta del backend', () {
    final ruta = Ruta.fromJson(json);

    expect(ruta.idRuta, 1);
    expect(ruta.codigo, 'RD-11');
    expect(ruta.puntoInicio, 'A.H. Los Almendros');
    expect(ruta.activa, isTrue);
    expect(ruta.tiempoEstimado, isNull);
    expect(ruta.paraderosDestacados, isEmpty);
  });

  test('el buscador ignora mayúsculas y revisa varios campos', () {
    final ruta = Ruta.fromJson(json);

    expect(ruta.coincideCon(''), isTrue);
    expect(ruta.coincideCon('rd-11'), isTrue);
    expect(ruta.coincideCon('ALMENDROS'), isTrue);
    expect(ruta.coincideCon('santo toribio'), isTrue);
    expect(ruta.coincideCon('tacalá'), isFalse);
  });

  test('el color de la ficha rota entre azul, verde y naranja', () {
    Ruta con(int id) => Ruta(idRuta: id, nombre: 'Ruta $id');

    expect(con(1).tono, RutaTono.azul);
    expect(con(2).tono, RutaTono.verde);
    expect(con(3).tono, RutaTono.naranja);
    expect(con(4).tono, RutaTono.azul);
  });
}
