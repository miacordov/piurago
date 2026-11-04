import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/data/ubicacion/servicio_ubicacion.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Plataforma de geolocalización falsa: reemplaza al plugin nativo para
/// probar GeolocatorServicioUbicacion sin GPS ni navegador.
class _PlataformaFalsa extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool servicioActivo = true;
  LocationPermission permiso = LocationPermission.denied;
  LocationPermission respuestaDialogo = LocationPermission.whileInUse;
  int dialogosMostrados = 0;
  int ajustesAppAbiertos = 0;
  int ajustesUbicacionAbiertos = 0;
  LocationSettings? ultimosAjustes;
  List<Position> posiciones = const [];

  @override
  Future<bool> isLocationServiceEnabled() async => servicioActivo;

  @override
  Future<LocationPermission> checkPermission() async => permiso;

  @override
  Future<LocationPermission> requestPermission() async {
    dialogosMostrados++;
    permiso = respuestaDialogo;
    return permiso;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    ultimosAjustes = locationSettings;
    return Stream.fromIterable(posiciones);
  }

  @override
  Future<bool> openAppSettings() async {
    ajustesAppAbiertos++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    ajustesUbicacionAbiertos++;
    return true;
  }
}

Position _posicion(double lat, double lng, {double precision = 12}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2026, 11, 4),
    accuracy: precision,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  group('GeolocatorServicioUbicacion', () {
    late _PlataformaFalsa plataforma;
    const servicio = GeolocatorServicioUbicacion(esWeb: false);

    setUp(() {
      plataforma = _PlataformaFalsa();
      GeolocatorPlatform.instance = plataforma;
    });

    test('verificar() traduce el permiso sin mostrar el diálogo', () async {
      plataforma.permiso = LocationPermission.whileInUse;
      expect(await servicio.verificar(), EstadoPermisoUbicacion.concedido);

      plataforma.permiso = LocationPermission.always;
      expect(await servicio.verificar(), EstadoPermisoUbicacion.concedido);

      plataforma.permiso = LocationPermission.denied;
      expect(await servicio.verificar(), EstadoPermisoUbicacion.denegado);

      plataforma.permiso = LocationPermission.deniedForever;
      expect(
        await servicio.verificar(),
        EstadoPermisoUbicacion.denegadoParaSiempre,
      );
      expect(plataforma.dialogosMostrados, 0);
    });

    test('verificar() avisa si el GPS del equipo está apagado', () async {
      plataforma
        ..servicioActivo = false
        ..permiso = LocationPermission.whileInUse;

      expect(
        await servicio.verificar(),
        EstadoPermisoUbicacion.servicioDesactivado,
      );
    });

    test('solicitar() muestra el diálogo nativo si el permiso falta', () async {
      plataforma.respuestaDialogo = LocationPermission.whileInUse;

      expect(await servicio.solicitar(), EstadoPermisoUbicacion.concedido);
      expect(plataforma.dialogosMostrados, 1);
    });

    test('solicitar() devuelve denegado si la persona lo rechaza', () async {
      plataforma.respuestaDialogo = LocationPermission.denied;

      expect(await servicio.solicitar(), EstadoPermisoUbicacion.denegado);
    });

    test('solicitar() no vuelve a preguntar si ya está concedido', () async {
      plataforma.permiso = LocationPermission.whileInUse;

      expect(await servicio.solicitar(), EstadoPermisoUbicacion.concedido);
      expect(plataforma.dialogosMostrados, 0);
    });

    test(
      'solicitar() no muestra el diálogo si fue denegado para siempre',
      () async {
        plataforma.permiso = LocationPermission.deniedForever;

        expect(
          await servicio.solicitar(),
          EstadoPermisoUbicacion.denegadoParaSiempre,
        );
        expect(plataforma.dialogosMostrados, 0);
      },
    );

    test('solicitar() con el GPS apagado no pide el permiso', () async {
      plataforma.servicioActivo = false;

      expect(
        await servicio.solicitar(),
        EstadoPermisoUbicacion.servicioDesactivado,
      );
      expect(plataforma.dialogosMostrados, 0);
    });

    test('posiciones() usa el distanceFilter y entrega la precisión', () async {
      plataforma.posiciones = [
        _posicion(-5.19, -80.63, precision: 8),
        _posicion(-5.20, -80.64, precision: 25),
      ];

      final recibidas = await servicio.posiciones(distanceFilter: 20).toList();

      expect(plataforma.ultimosAjustes?.distanceFilter, 20);
      expect(recibidas.map((p) => p.punto), const [
        LatLng(-5.19, -80.63),
        LatLng(-5.20, -80.64),
      ]);
      expect(recibidas.map((p) => p.precisionMetros), [8, 25]);
    });

    test('posiciones() usa un distanceFilter por defecto', () async {
      await servicio.posiciones().toList();

      expect(
        plataforma.ultimosAjustes?.distanceFilter,
        ServicioUbicacion.distanciaMinimaPorDefecto,
      );
    });

    test('escucharPosicion() entrega solo las coordenadas', () async {
      plataforma.posiciones = [_posicion(-5.19, -80.63)];

      expect(
        await servicio.escucharPosicion().first,
        const LatLng(-5.19, -80.63),
      );
    });

    test('abre los ajustes de la app y los de ubicación del sistema', () async {
      await servicio.abrirAjustesApp();
      await servicio.abrirAjustesUbicacion();

      expect(plataforma.ajustesAppAbiertos, 1);
      expect(plataforma.ajustesUbicacionAbiertos, 1);
    });

    test('indica si corre en el navegador', () {
      expect(const GeolocatorServicioUbicacion(esWeb: true).esWeb, isTrue);
      expect(const GeolocatorServicioUbicacion(esWeb: false).esWeb, isFalse);
    });
  });

  group('FakeServicioUbicacion', () {
    test('parte del estado indicado y solicitar() devuelve la respuesta '
        'configurada', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.denegado,
        respuestaSolicitud: EstadoPermisoUbicacion.denegadoParaSiempre,
      );

      expect(await fake.verificar(), EstadoPermisoUbicacion.denegado);
      expect(
        await fake.solicitar(),
        EstadoPermisoUbicacion.denegadoParaSiempre,
      );
      expect(
        await fake.verificar(),
        EstadoPermisoUbicacion.denegadoParaSiempre,
      );
      expect(fake.vecesSolicitado, 1);
    });

    test('emite las posiciones que la prueba le indica', () async {
      final fake = FakeServicioUbicacion(
        estadoInicial: EstadoPermisoUbicacion.concedido,
      );
      final recibidas = <PosicionUsuario>[];
      final sub = fake.posiciones(distanceFilter: 5).listen(recibidas.add);

      fake.emitir(const PosicionUsuario(LatLng(-5.19, -80.63), 10));
      await Future<void>.delayed(Duration.zero);

      expect(recibidas.single.punto, const LatLng(-5.19, -80.63));
      expect(recibidas.single.precisionMetros, 10);
      expect(fake.ultimoDistanceFilter, 5);
      await sub.cancel();
    });

    test('cuenta cuántas veces se abrieron los ajustes', () async {
      final fake = FakeServicioUbicacion(esWeb: true);

      await fake.abrirAjustesApp();
      await fake.abrirAjustesUbicacion();
      await fake.abrirAjustesUbicacion();

      expect(fake.esWeb, isTrue);
      expect(fake.vecesAjustesApp, 1);
      expect(fake.vecesAjustesUbicacion, 2);
    });
  });
}
