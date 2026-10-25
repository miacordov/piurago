/// Un paradero de una ruta. Los campos coinciden con la respuesta de
/// `GET /api/rutas/{id}/paraderos` del backend (ParaderoResponseDTO).
class Paradero {
  const Paradero({
    required this.idParadero,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.ordenSecuencial,
    this.etaMinutos,
  });

  factory Paradero.fromJson(Map<String, dynamic> json) {
    return Paradero(
      idParadero: (json['idParadero'] as num).toInt(),
      nombre: json['nombre'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      ordenSecuencial: (json['ordenSecuencial'] as num).toInt(),
    );
  }

  final int idParadero;
  final String nombre;
  final double latitud;
  final double longitud;
  final int ordenSecuencial;

  /// Minutos hasta que llega la unidad a este paradero. El backend todavía no
  /// lo entrega por paradero, así que hoy solo viene en los datos de prueba.
  final int? etaMinutos;
}
