import 'package:flutter/material.dart';

import 'app.dart';
import 'data/api/almacen_sesion.dart';
import 'data/api/auth_service.dart';
import 'data/api/http_rutas_repository.dart';
import 'data/lugares/buscador_lugares.dart';
import 'data/lugares/buscador_lugares_prueba.dart';
import 'data/lugares/lugares_piura.dart';
import 'data/lugares/photon_buscador_lugares.dart';
import 'data/rutas_repository.dart';

/// Con --dart-define=DATOS_PRUEBA=true el buscador de lugares y rutas no usa la red.
const _datosPrueba = bool.fromEnvironment('DATOS_PRUEBA');

/// URL del backend Spring Boot de PiuraGo:
/// --dart-define=API_URL=http://localhost:8080
const _urlApi = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080',
);

/// Dirección del buscador de lugares (un servicio compatible con Photon):
/// --dart-define=GEOCODER_URL=https://...
const _urlBuscador = String.fromEnvironment(
  'GEOCODER_URL',
  defaultValue: PhotonBuscadorLugares.urlPublica,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final BuscadorLugares buscador = _datosPrueba
      ? const BuscadorLugaresPrueba()
      : PhotonBuscadorLugares(url: Uri.parse(_urlBuscador));

  // La sesión se guarda cifrada en el dispositivo y se recupera al abrir.
  final authService = AuthService(
    baseUrl: Uri.parse(_urlApi),
    almacen: AlmacenSesionSegura(),
  );
  await authService.restaurarSesion();
  final RutasRepository rutasRepo = _datosPrueba
      ? const FakeRutasRepository()
      : HttpRutasRepository(
          baseUrl: Uri.parse(_urlApi),
          authService: authService,
          fallback: const FakeRutasRepository(),
        );

  runApp(
    PiuraGoApp(
      rutasRepository: rutasRepo,
      authService: _datosPrueba ? null : authService,
      buscadorLugares: buscador,
      lugaresConocidos: lugaresPiura,
    ),
  );
}
