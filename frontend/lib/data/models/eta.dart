/// Tiempo hasta la próxima unidad de una ruta, según el backend
/// (`GET /api/reportes-gps/eta/{idRuta}`, EtaResponseDTO).
class Eta {
  const Eta({required this.minutos, required this.simulado});

  /// Lee la respuesta del backend: `minutosEstimados` y `origen` ("REAL" con
  /// pasajeros compartiendo el GPS; "SIMULADO" si se calcula con la
  /// frecuencia de la línea). Los minutos se redondean hacia arriba.
  factory Eta.fromJson(Map<String, dynamic> json) {
    final minutos = (json['minutosEstimados'] as num).toDouble();
    return Eta(minutos: minutos.ceil(), simulado: json['origen'] != 'REAL');
  }

  final int minutos;

  /// No hay pasajeros compartiendo el GPS: el tiempo es una estimación.
  final bool simulado;
}
