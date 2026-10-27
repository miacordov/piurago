/// Nivel de congestión según la velocidad de las combis (umbrales del
/// backend: ALTA por debajo de 10 km/h, MEDIA por debajo de 18 km/h).
enum NivelCongestion {
  baja,
  media,
  alta;

  static NivelCongestion? desde(Object? valor) => switch (valor) {
    'BAJA' => NivelCongestion.baja,
    'MEDIA' => NivelCongestion.media,
    'ALTA' => NivelCongestion.alta,
    _ => null,
  };
}

/// Nivel de una franja del día (para las barras).
class FranjaCongestionResumen {
  const FranjaCongestionResumen(
    this.franjaHoraria,
    this.nivel,
    this.velocidadPromedio,
  );

  factory FranjaCongestionResumen.fromJson(Map<String, dynamic> json) =>
      FranjaCongestionResumen(
        json['franjaHoraria'] as String,
        NivelCongestion.desde(json['nivel']),
        (json['velocidadPromedio'] as num?)?.toDouble(),
      );

  final String franjaHoraria;

  /// Null si todavía no hay viajes compartidos en esa franja.
  final NivelCongestion? nivel;
  final double? velocidadPromedio;
}

/// Tramo lento entre dos paraderos seguidos de una línea.
class TramoCritico {
  const TramoCritico({
    required this.codigoRuta,
    required this.nombreRuta,
    required this.desde,
    required this.hasta,
    required this.velocidadPromedio,
    required this.nivel,
    required this.demoraMinutos,
  });

  factory TramoCritico.fromJson(Map<String, dynamic> json) => TramoCritico(
    codigoRuta: json['codigoRuta'] as String?,
    nombreRuta: json['nombreRuta'] as String?,
    desde: json['desde'] as String? ?? '',
    hasta: json['hasta'] as String?,
    velocidadPromedio: (json['velocidadPromedio'] as num?)?.toDouble() ?? 0,
    nivel: NivelCongestion.desde(json['nivel']) ?? NivelCongestion.media,
    demoraMinutos: (json['demoraMinutos'] as num?)?.toInt() ?? 0,
  );

  final String? codigoRuta;
  final String? nombreRuta;
  final String desde;

  /// Null si el tramo empieza en el último paradero.
  final String? hasta;
  final double velocidadPromedio;
  final NivelCongestion nivel;

  /// Minutos de más en el tramo frente a ir sin tráfico.
  final int demoraMinutos;
}

/// Congestión de la ciudad en una franja y un día, según el backend
/// (`GET /api/historico-congestion/resumen`, ResumenCongestionDTO). Se arma
/// con los viajes que comparten los pasajeros; se recalcula cada hora.
class ResumenCongestion {
  const ResumenCongestion({
    required this.franjaHoraria,
    required this.diaSemana,
    this.nivelGeneral,
    this.velocidadPromedio,
    this.demoraPromedio,
    required this.rutasConDatos,
    required this.puntosCriticos,
    required this.porFranja,
    required this.tramosCriticos,
  });

  factory ResumenCongestion.fromJson(Map<String, dynamic> json) =>
      ResumenCongestion(
        franjaHoraria: json['franjaHoraria'] as String,
        diaSemana: json['diaSemana'] as String,
        nivelGeneral: NivelCongestion.desde(json['nivelGeneral']),
        velocidadPromedio: (json['velocidadPromedio'] as num?)?.toDouble(),
        demoraPromedio: (json['demoraPromedio'] as num?)?.toDouble(),
        rutasConDatos: (json['rutasConDatos'] as num?)?.toInt() ?? 0,
        puntosCriticos: (json['puntosCriticos'] as num?)?.toInt() ?? 0,
        porFranja: [
          for (final f in json['porFranja'] as List<dynamic>? ?? const [])
            FranjaCongestionResumen.fromJson(f as Map<String, dynamic>),
        ],
        tramosCriticos: [
          for (final t in json['tramosCriticos'] as List<dynamic>? ?? const [])
            TramoCritico.fromJson(t as Map<String, dynamic>),
        ],
      );

  /// MANANA_PICO, MEDIO_DIA, TARDE_PICO o NOCHE.
  final String franjaHoraria;

  /// LUN … DOM.
  final String diaSemana;

  /// Null si todavía no hay viajes compartidos en la franja.
  final NivelCongestion? nivelGeneral;
  final double? velocidadPromedio;

  /// Minutos de más por kilómetro frente a ir a 25 km/h.
  final double? demoraPromedio;
  final int rutasConDatos;

  /// Desplazamientos registrados a menos de 10 km/h.
  final int puntosCriticos;
  final List<FranjaCongestionResumen> porFranja;
  final List<TramoCritico> tramosCriticos;

  bool get tieneDatos => nivelGeneral != null;
}
