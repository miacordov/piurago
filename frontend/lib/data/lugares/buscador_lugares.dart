import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';

/// Busca lugares por nombre mientras el usuario escribe (calles, barrios,
/// negocios, sitios conocidos), de Piura y de fuera. Es intercambiable: hoy
/// se usa Photon (PhotonBuscadorLugares) y, con DATOS_PRUEBA=true, un
/// buscador local sin red (BuscadorLugaresPrueba).
abstract class BuscadorLugares {
  /// Lugares que coinciden con [texto], primero los cercanos a Piura.
  /// Lanza [BusquedaLugaresException] si el servicio no responde bien.
  Future<List<Lugar>> buscar(String texto);

  /// Atribución que se muestra debajo de las sugerencias.
  String get atribucion;
}

/// El servicio de lugares falló (sin red, error del servidor o límite de uso).
class BusquedaLugaresException implements Exception {
  const BusquedaLugaresException(this.mensaje, {this.limiteExcedido = false});

  final String mensaje;

  /// El servicio respondió 429: hay que esperar antes de volver a pedir.
  final bool limiteExcedido;

  @override
  String toString() => 'BusquedaLugaresException: $mensaje';
}

/// Punto fijo (Plaza de Armas de Piura, aproximada) hacia el que se ordenan
/// los resultados. Es lo único que se envía junto con el texto: nunca la
/// ubicación real del usuario.
const centroBusquedaPiura = LatLng(-5.1945, -80.6328);

/// Cantidad máxima de lugares que se piden al servicio.
const maximoLugaresEnLinea = 6;

/// Abreviaturas comunes de las direcciones de Piura y la palabra completa que
/// entienden los buscadores.
const _abreviaturas = {
  'jr': 'jirón',
  'av': 'avenida',
  'avda': 'avenida',
  'psje': 'pasaje',
  'pje': 'pasaje',
  'ca': 'calle',
  'cl': 'calle',
  'urb': 'urbanización',
  'prol': 'prolongación',
  'carr': 'carretera',
  'aahh': 'asentamiento humano',
  'univ': 'universidad',
};

/// Cambia las abreviaturas por la palabra completa: "jr ica" -> "jirón ica".
String expandirAbreviaturas(String texto) {
  return texto
      .trim()
      .split(RegExp(r'\s+'))
      .map((palabra) {
        final clave = palabra.toLowerCase().replaceAll('.', '');
        return _abreviaturas[clave] ?? palabra;
      })
      .join(' ');
}
