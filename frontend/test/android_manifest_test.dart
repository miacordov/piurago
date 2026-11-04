import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sin estos permisos en el manifiesto, Android no muestra el diálogo de
/// ubicación y geolocator devuelve "denegado para siempre".
void main() {
  test('el AndroidManifest declara los permisos de ubicación', () {
    final manifiesto = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    for (final permiso in [
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
    ]) {
      expect(
        manifiesto,
        contains('<uses-permission android:name="$permiso"'),
        reason: 'Falta $permiso en el AndroidManifest',
      );
    }
  });
}
