import 'package:latlong2/latlong.dart';
import 'package:piurago/data/lugares/buscador_lugares.dart';
import 'package:piurago/data/models/lugar.dart';
import 'package:piurago/data/models/paradero.dart';
import 'package:piurago/data/models/ruta.dart';
import 'package:piurago/data/rutas_repository.dart';

/// Paradero de prueba. Todos están sobre la misma longitud salvo que se
/// indique otra: 0.001° de latitud son unos 111 m.
Paradero paraderoPrueba(
  int id,
  String nombre,
  double latitud, [
  double longitud = -80.63,
]) {
  return Paradero(
    idParadero: id,
    nombre: nombre,
    latitud: latitud,
    longitud: longitud,
    ordenSecuencial: id,
  );
}

/// Rutas de prueba con coordenadas fijas (no usan los datos reales):
/// - Línea A pasa por Mercado Central (norte) y Hospital Sur (sur).
/// - Línea B pasa unos 222 m más lejos de esos dos lugares.
/// - Línea C tiene un paradero en el norte y otro muy lejos (Estadio Lejano).
/// - Línea D pasa por los dos extremos, pero está fuera de servicio.
/// - Línea E tiene un solo paradero.
const rutasPrueba = <Ruta>[
  Ruta(
    idRuta: 1,
    codigo: 'A-01',
    nombre: 'Línea A',
    empresa: 'Empresa A',
    tipoServicio: 'Urbana',
    frecuenciaMinutos: 10,
    horario: '06:00–22:00',
    pasaje: 1.50,
  ),
  Ruta(
    idRuta: 2,
    codigo: 'B-02',
    nombre: 'Línea B',
    empresa: 'Empresa B',
    tipoServicio: 'Regulada',
    frecuenciaMinutos: 8,
    pasaje: 1.20,
  ),
  Ruta(idRuta: 3, codigo: 'C-03', nombre: 'Línea C', empresa: 'Empresa C'),
  Ruta(idRuta: 4, codigo: 'D-04', nombre: 'Línea D', activa: false),
  Ruta(idRuta: 5, codigo: 'E-05', nombre: 'Línea E'),
];

final paraderosPrueba = <int, List<Paradero>>{
  1: [
    paraderoPrueba(1, 'Mercado Central', -5.2010),
    paraderoPrueba(2, 'Plaza Norte', -5.2100),
    paraderoPrueba(3, 'Hospital Sur', -5.2190),
  ],
  2: [
    paraderoPrueba(4, 'Mercado Chico', -5.2030),
    paraderoPrueba(5, 'Colegio Sur', -5.2170),
  ],
  3: [
    // Mismo nombre que en la Línea A, con otra coordenada.
    paraderoPrueba(6, 'mercado central', -5.2008),
    paraderoPrueba(7, 'Estadio Lejano', -5.2400, -80.6600),
  ],
  4: [
    paraderoPrueba(8, 'Terminal Norte', -5.2000),
    paraderoPrueba(9, 'Terminal Sur', -5.2200),
  ],
  5: [paraderoPrueba(10, 'Parque Solo', -5.2050)],
};

/// Repositorio de prueba que cuenta las llamadas y puede fallar a pedido.
class RepositorioPrueba implements RutasRepository {
  RepositorioPrueba({this.fallarParaderos = false});

  bool fallarParaderos;
  int llamadasListar = 0;
  final llamadasParaderos = <int, int>{};

  @override
  Future<List<Ruta>> listar() async {
    llamadasListar++;
    return rutasPrueba;
  }

  @override
  Future<List<Paradero>> paraderos(int idRuta) async {
    llamadasParaderos[idRuta] = (llamadasParaderos[idRuta] ?? 0) + 1;
    if (fallarParaderos) throw Exception('sin conexión');
    return paraderosPrueba[idRuta] ?? const <Paradero>[];
  }

  @override
  bool get esDemostracion => true;
}

/// Buscador de lugares en línea falso (sin red): anota lo que se le pide y
/// responde "Resultado de {texto}" lejos de las líneas, salvo que se indique
/// otra respuesta. Puede fallar o responder como un 429.
class BuscadorFalso implements BuscadorLugares {
  BuscadorFalso({this.fallar = false, this.limite = false});

  bool fallar;
  bool limite;
  final pedidos = <String>[];
  final respuestas = <String, Future<List<Lugar>>>{};

  @override
  Future<List<Lugar>> buscar(String texto) {
    pedidos.add(texto);
    if (limite) {
      return Future.error(
        const BusquedaLugaresException('429', limiteExcedido: true),
      );
    }
    if (fallar) {
      return Future.error(const BusquedaLugaresException('sin red'));
    }
    return respuestas[texto] ??
        Future.value([
          Lugar('Resultado de $texto', const LatLng(-5.3000, -80.7000)),
        ]);
  }

  @override
  String get atribucion =>
      'Búsqueda de lugares: Photon · © OpenStreetMap contributors';
}
