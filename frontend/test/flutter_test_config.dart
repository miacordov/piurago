import 'dart:async';

import 'package:piurago/features/viaje/planificador_viaje.dart';

/// Hora fija para todas las pruebas: el planificador marca las líneas fuera
/// de horario según la hora, y las pruebas no deben depender de cuándo se
/// corren.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PlanificadorViaje.relojPorDefecto = () => DateTime(2026, 11, 27, 12);
  await testMain();
}
