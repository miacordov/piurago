import 'package:flutter/material.dart';

import 'app.dart';
import 'data/lugares/buscador_lugares.dart';
import 'data/lugares/buscador_lugares_prueba.dart';
import 'data/lugares/photon_buscador_lugares.dart';

/// Con --dart-define=DATOS_PRUEBA=true el buscador de lugares no usa la red.
const _datosPrueba = bool.fromEnvironment('DATOS_PRUEBA');

/// Dirección del buscador de lugares (un servicio compatible con Photon):
/// --dart-define=GEOCODER_URL=https://...
const _urlBuscador = String.fromEnvironment(
  'GEOCODER_URL',
  defaultValue: PhotonBuscadorLugares.urlPublica,
);

void main() {
  final BuscadorLugares buscador = _datosPrueba
      ? const BuscadorLugaresPrueba()
      : PhotonBuscadorLugares(url: Uri.parse(_urlBuscador));
  runApp(PiuraGoApp(buscadorLugares: buscador));
}
