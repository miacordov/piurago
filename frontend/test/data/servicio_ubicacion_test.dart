import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/data/ubicacion/servicio_ubicacion.dart';

void main() {
  group('ServicioUbicacion (FakeServicioUbicacion)', () {
    test('inicia con el estado de permiso asignado y permite solicitarlo', () async {
      final fake = FakeServicioUbicacion(
        permisoInicial: EstadoPermisoUbicacion.denegado,
      );

      expect(await fake.verificarPermiso(), EstadoPermisoUbicacion.denegado);
      expect(fake.vecesSolicitado, 0);

      final resultado = await fake.solicitarPermiso();

      expect(resultado, EstadoPermisoUbicacion.concedido);
      expect(fake.vecesSolicitado, 1);
      expect(await fake.verificarPermiso(), EstadoPermisoUbicacion.concedido);
    });

    test('devuelve posición actual solo cuando el permiso está concedido', () async {
      const piuraCentro = LatLng(-5.1944, -80.6328);
      final fake = FakeServicioUbicacion(
        permisoInicial: EstadoPermisoUbicacion.denegado,
        posicionFija: piuraCentro,
      );

      // Sin permiso, no entrega posición
      expect(await fake.obtenerPosicionActual(), isNull);

      // Al conceder el permiso, entrega la posición GPS
      await fake.solicitarPermiso();
      final pos = await fake.obtenerPosicionActual();

      expect(pos, isNotNull);
      expect(pos!.latitude, piuraCentro.latitude);
      expect(pos.longitude, piuraCentro.longitude);
    });

    test('escucharPosicion() emite las coordenadas en el Stream', () async {
      const piura = LatLng(-5.2000, -80.6300);
      final fake = FakeServicioUbicacion(
        permisoInicial: EstadoPermisoUbicacion.concedido,
        posicionFija: piura,
      );

      final stream = fake.escucharPosicion();
      final punto = await stream.first;

      expect(punto.latitude, piura.latitude);
      expect(punto.longitude, piura.longitude);
    });
  });
}
