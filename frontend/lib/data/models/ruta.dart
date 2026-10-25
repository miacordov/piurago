/// Color de la ficha de una línea en la lista de rutas.
enum RutaTono { azul, verde, naranja }

/// Una ruta de transporte. Los campos principales coinciden con la respuesta
/// de `GET /api/rutas` del backend (RutaResponseDTO).
class Ruta {
  const Ruta({
    required this.idRuta,
    required this.nombre,
    this.codigo,
    this.empresa,
    this.puntoInicio,
    this.puntoFinal,
    this.sentido,
    this.descripcion,
    this.recorrido,
    this.activa = true,
    this.tiempoEstimado,
    this.frecuenciaMinutos,
    this.paraderosDestacados = const [],
    this.etaMinutos,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    return Ruta(
      idRuta: (json['idRuta'] as num).toInt(),
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String?,
      empresa: json['empresa'] as String?,
      puntoInicio: json['puntoInicio'] as String?,
      puntoFinal: json['puntoFinal'] as String?,
      sentido: json['sentido'] as String?,
      descripcion: json['descripcion'] as String?,
      recorrido: json['recorrido'] as String?,
      activa: json['activa'] as bool? ?? true,
      tiempoEstimado: (json['tiempoEstimado'] as num?)?.toInt(),
      frecuenciaMinutos: (json['frecuenciaMinutos'] as num?)?.toInt(),
    );
  }

  final int idRuta;
  final String nombre;
  final String? codigo;
  final String? empresa;
  final String? puntoInicio;
  final String? puntoFinal;
  final String? sentido;
  final String? descripcion;
  final String? recorrido;
  final bool activa;
  final int? tiempoEstimado;
  final int? frecuenciaMinutos;

  /// Paraderos que se muestran en la tarjeta. El backend todavía no los
  /// entrega junto con la ruta: se piden aparte (`/api/rutas/{id}/paraderos`).
  final List<String> paraderosDestacados;

  /// Minutos hasta la próxima unidad, si se conocen.
  final int? etaMinutos;

  RutaTono get tono => RutaTono.values[(idRuta - 1) % RutaTono.values.length];

  /// Indica si la ruta coincide con lo que escribió el usuario en el buscador.
  bool coincideCon(String consulta) {
    final q = consulta.trim().toLowerCase();
    if (q.isEmpty) return true;
    final campos = <String?>[
      nombre,
      codigo,
      empresa,
      puntoInicio,
      puntoFinal,
      descripcion,
      ...paraderosDestacados,
    ];
    return campos.any((c) => c != null && c.toLowerCase().contains(q));
  }
}
