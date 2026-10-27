@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/core/guardar_archivo.dart';

/// Solo corre en el navegador: flutter test --platform chrome test/core
void main() {
  test('en el navegador descarga el archivo sin errores', () async {
    final guardado = await const GuardadorPorPlataforma().guardar(
      nombre: 'congestion-piura-prueba.xlsx',
      bytes: Uint8List.fromList([0x50, 0x4b, 3, 4]),
      tipo: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    expect(guardado, isTrue);
  });
}
