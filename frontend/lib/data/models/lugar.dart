import 'package:latlong2/latlong.dart';

/// Qué es un lugar del buscador (cambia el ícono de la sugerencia).
enum TipoLugar { paradero, calle, zona, lugar }

/// Un lugar que el usuario puede elegir como origen o destino.
class Lugar {
  const Lugar(
    this.nombre,
    this.posicion, {
    this.tipo = TipoLugar.lugar,
    this.detalle,
  });

  final String nombre;
  final LatLng posicion;
  final TipoLugar tipo;

  /// Dónde queda, para distinguir lugares con el mismo nombre (por ejemplo,
  /// "Urbanización 4 de Enero, Piura, Perú").
  final String? detalle;
}
