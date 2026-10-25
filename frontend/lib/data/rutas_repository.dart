import 'models/paradero.dart';
import 'models/ruta.dart';

/// Fuente de las rutas. Hoy hay una implementación con datos de prueba; la
/// versión que llama al backend se agrega después con la misma interfaz.
abstract class RutasRepository {
  Future<List<Ruta>> listar();

  /// Paraderos de una ruta, en orden.
  Future<List<Paradero>> paraderos(int idRuta);

  /// Indica que los datos son de prueba: la interfaz lo avisa al usuario.
  bool get esDemostracion;
}

/// Datos de prueba tomados del prototipo (no son rutas reales de Piura).
class FakeRutasRepository implements RutasRepository {
  const FakeRutasRepository();

  @override
  Future<List<Ruta>> listar() async => _datos;

  @override
  Future<List<Paradero>> paraderos(int idRuta) async =>
      idRuta == 1 ? _paraderosLinea10 : const <Paradero>[];

  @override
  bool get esDemostracion => true;

  /// Recorrido ilustrativo de la Línea 10. Las coordenadas son APROXIMADAS y
  /// de demostración: no son paraderos reales. Los reales se cargan al final
  /// del proyecto. Solo la primera (Plaza de Armas) es una ubicación real.
  static const _paraderosLinea10 = <Paradero>[
    Paradero(
      idParadero: 1,
      nombre: 'Plaza de Armas',
      latitud: -5.1945,
      longitud: -80.6328,
      ordenSecuencial: 1,
      etaMinutos: 0,
    ),
    Paradero(
      idParadero: 2,
      nombre: 'Av. Grau',
      latitud: -5.1905,
      longitud: -80.6322,
      ordenSecuencial: 2,
      etaMinutos: 2,
    ),
    Paradero(
      idParadero: 3,
      nombre: 'Open Plaza',
      latitud: -5.1862,
      longitud: -80.6310,
      ordenSecuencial: 3,
      etaMinutos: 5,
    ),
    Paradero(
      idParadero: 4,
      nombre: 'Universidad Nacional',
      latitud: -5.1820,
      longitud: -80.6296,
      ordenSecuencial: 4,
      etaMinutos: 8,
    ),
    Paradero(
      idParadero: 5,
      nombre: 'Los Ejidos',
      latitud: -5.1775,
      longitud: -80.6275,
      ordenSecuencial: 5,
      etaMinutos: 11,
    ),
  ];

  static const _datos = <Ruta>[
    Ruta(
      idRuta: 1,
      nombre: 'Línea 10 · El Moradito',
      descripcion: 'Castilla · Catacaos · Mercado Central',
      paraderosDestacados: ['Plaza de Armas', 'Av. Grau', 'Open Plaza'],
      etaMinutos: 4,
    ),
    Ruta(
      idRuta: 2,
      nombre: 'Ruta B · Combi Interurbana',
      descripcion: 'Piura · Veintiséis de Octubre',
      paraderosDestacados: [
        'Plaza de Armas',
        'Av. Grau',
        'Complejo de Mercados',
      ],
      etaMinutos: 7,
    ),
    Ruta(
      idRuta: 3,
      nombre: 'Línea 6 · Emutsa',
      descripcion: 'Castilla · Centro · Santa Rosa',
      paraderosDestacados: [
        'Castilla',
        'Puente Sánchez Cerro',
        'Centro de Piura',
      ],
      etaMinutos: 11,
    ),
    Ruta(
      idRuta: 4,
      nombre: 'Línea 1 · San Antonio',
      descripcion: 'Piura · Los Ejidos · Centro',
      paraderosDestacados: [
        'Los Ejidos',
        'Av. Sánchez Cerro',
        'Plaza de Armas',
      ],
      etaMinutos: 6,
    ),
    Ruta(
      idRuta: 5,
      nombre: 'Ruta A · Superstar',
      descripcion: 'Castilla · Aeropuerto · Centro',
      paraderosDestacados: ['Castilla', 'Aeropuerto', 'Puente Cáceres'],
      etaMinutos: 9,
    ),
    Ruta(
      idRuta: 6,
      nombre: 'Ruta C · Nueva Alternativa',
      descripcion: 'Veintiséis de Octubre · Centro',
      paraderosDestacados: [
        'Veintiséis de Octubre',
        'Av. Chulucanas',
        'Mercado Modelo',
      ],
      etaMinutos: 12,
    ),
    Ruta(
      idRuta: 7,
      nombre: 'Línea 4 · El Piuranito',
      descripcion: 'Piura · Santa Julia · Castilla',
      paraderosDestacados: [
        'Santa Julia',
        'Av. Guardia Civil',
        'Puente Sánchez Cerro',
      ],
      etaMinutos: 8,
    ),
    Ruta(
      idRuta: 8,
      nombre: 'Línea 5 · Sol de Piura',
      descripcion: 'Centro · Miraflores · Catacaos',
      paraderosDestacados: ['Centro de Piura', 'Miraflores', 'Óvalo Cáceres'],
      etaMinutos: 10,
    ),
    Ruta(
      idRuta: 9,
      nombre: 'Ruta D · La Guadalupe',
      descripcion: 'Piura · Tacalá · Castilla',
      paraderosDestacados: ['Terminal Piura', 'Av. Grau', 'Tacalá'],
      etaMinutos: 14,
    ),
  ];
}
