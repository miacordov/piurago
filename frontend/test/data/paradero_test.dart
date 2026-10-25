import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/data/models/paradero.dart';

void main() {
  test('fromJson lee la respuesta de /api/rutas/{id}/paraderos', () {
    final json = <String, dynamic>{
      'idParadero': 7,
      'nombre': 'Plaza de Armas',
      'latitud': -5.1945,
      'longitud': -80.6328,
      'ordenSecuencial': 1,
    };

    final paradero = Paradero.fromJson(json);

    expect(paradero.idParadero, 7);
    expect(paradero.nombre, 'Plaza de Armas');
    expect(paradero.latitud, -5.1945);
    expect(paradero.longitud, -80.6328);
    expect(paradero.ordenSecuencial, 1);
    expect(paradero.etaMinutos, isNull);
  });

  test('acepta coordenadas enteras', () {
    final paradero = Paradero.fromJson(<String, dynamic>{
      'idParadero': 1,
      'nombre': 'Prueba',
      'latitud': -5,
      'longitud': -80,
      'ordenSecuencial': 2,
    });

    expect(paradero.latitud, -5.0);
    expect(paradero.longitud, -80.0);
  });
}
