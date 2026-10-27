import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'data/api/auth_service.dart';
import 'data/lugares/buscador_lugares.dart';
import 'data/models/lugar.dart';
import 'data/rutas_repository.dart';
import 'data/ubicacion/servicio_ubicacion.dart';
import 'features/auth/login_page.dart';
import 'features/congestion/congestion_page.dart';
import 'features/location/location_page.dart';
import 'features/map/map_page.dart';
import 'features/routes/routes_page.dart';

class PiuraGoApp extends StatelessWidget {
  const PiuraGoApp({
    super.key,
    this.rutasRepository,
    this.authService,
    this.buscadorLugares,
    this.lugaresConocidos = const [],
    this.mostrarMapaBase = true,
    this.servicioUbicacion,
  });

  /// Fuente de datos de las rutas. Si no se indica, se usan datos de prueba.
  final RutasRepository? rutasRepository;

  /// Sesión con el backend. Si hay una sesión registrada guardada, la app
  /// abre directamente en Rutas. Sin él (pruebas, modo demo), el acceso no
  /// llama al backend.
  final AuthService? authService;

  /// Buscador de lugares en línea de "¿A dónde vas?". Si no se indica, solo
  /// se sugieren los paraderos (por ejemplo, en las pruebas, sin internet).
  final BuscadorLugares? buscadorLugares;

  /// Base propia de calles y lugares para las sugerencias (en la app se usa
  /// lugaresPiura; en las pruebas, ninguna).
  final List<Lugar> lugaresConocidos;

  /// Permite desactivar el mapa real (por ejemplo, en las pruebas, que no
  /// tienen acceso a internet).
  final bool mostrarMapaBase;

  /// Servicio de geolocalización. Si no se indica, usa Geolocator real.
  final ServicioUbicacion? servicioUbicacion;

  @override
  Widget build(BuildContext context) {
    final repository = rutasRepository ?? const FakeRutasRepository();
    final ubicacion = servicioUbicacion ?? const GeolocatorServicioUbicacion();

    return MaterialApp(
      title: 'PiuraGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: (authService?.esRegistrado ?? false)
          ? AppRoutes.rutas
          : AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => LoginPage(authService: authService),
        AppRoutes.ubicacion: (_) => LocationPage(servicioUbicacion: ubicacion),
        AppRoutes.rutas: (_) => RoutesPage(repository: repository),
        AppRoutes.mapa: (context) {
          final idRuta = ModalRoute.of(context)?.settings.arguments as int?;
          return MapPage(
            repository: repository,
            buscadorLugares: buscadorLugares,
            lugaresConocidos: lugaresConocidos,
            idRuta: idRuta,
            mostrarMapa: mostrarMapaBase,
            servicioUbicacion: ubicacion,
          );
        },
        AppRoutes.congestion: (_) => const CongestionPage(),
      },
    );
  }
}
