import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'data/rutas_repository.dart';
import 'features/auth/login_page.dart';
import 'features/location/location_page.dart';
import 'features/map/map_page.dart';
import 'features/routes/routes_page.dart';

class PiuraGoApp extends StatelessWidget {
  const PiuraGoApp({
    super.key,
    this.rutasRepository,
    this.mostrarMapaBase = true,
  });

  /// Fuente de datos de las rutas. Si no se indica, se usan datos de prueba.
  final RutasRepository? rutasRepository;

  /// Permite desactivar el mapa real (por ejemplo, en las pruebas, que no
  /// tienen acceso a internet).
  final bool mostrarMapaBase;

  @override
  Widget build(BuildContext context) {
    final repository = rutasRepository ?? const FakeRutasRepository();
    return MaterialApp(
      title: 'PiuraGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.ubicacion: (_) => const LocationPage(),
        AppRoutes.rutas: (_) => RoutesPage(repository: repository),
        AppRoutes.mapa: (context) {
          final idRuta = ModalRoute.of(context)?.settings.arguments as int?;
          return MapPage(
            repository: repository,
            idRuta: idRuta,
            mostrarMapa: mostrarMapaBase,
          );
        },
      },
    );
  }
}
