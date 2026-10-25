import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import 'buscador_lugares.dart';
import 'indice_lugares.dart';

/// Buscador de lugares sin red, para --dart-define=DATOS_PRUEBA=true: busca
/// entre unos pocos lugares de Piura con coordenadas de OpenStreetMap.
class BuscadorLugaresPrueba implements BuscadorLugares {
  const BuscadorLugaresPrueba();

  static final _indice = IndiceLugares(const [
    Lugar(
      'Real Plaza Piura',
      LatLng(-5.18470, -80.64196),
      detalle: 'Avenida Sánchez Cerro, Piura, Perú',
    ),
    Lugar(
      'Avenida Sánchez Cerro',
      LatLng(-5.18367, -80.65200),
      tipo: TipoLugar.calle,
      detalle: 'Piura, Perú',
    ),
    Lugar(
      'Avenida Grau',
      LatLng(-5.20624, -80.62222),
      tipo: TipoLugar.calle,
      detalle: 'Talarita, Piura, Perú',
    ),
    Lugar(
      'Universidad Nacional de Piura',
      LatLng(-5.17754, -80.61776),
      detalle: 'Castilla, Piura, Perú',
    ),
    Lugar(
      'Hospital Regional Cayetano Heredia',
      LatLng(-5.18693, -80.62261),
      detalle: 'Castilla, Piura, Perú',
    ),
    Lugar(
      'Estadio Miguel Grau',
      LatLng(-5.19274, -80.61709),
      detalle: 'Castilla, Piura, Perú',
    ),
    Lugar(
      'Castilla',
      LatLng(-5.20163, -80.62248),
      tipo: TipoLugar.zona,
      detalle: 'Piura, Perú',
    ),
  ]);

  @override
  String get atribucion => 'Búsqueda de lugares de prueba (sin conexión)';

  @override
  Future<List<Lugar>> buscar(String texto) async => _indice.sugerir(texto);
}
