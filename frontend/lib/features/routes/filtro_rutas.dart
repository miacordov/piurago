import '../../data/lugares/indice_lugares.dart';
import '../../data/models/ruta.dart';

/// Tipos de servicio de las líneas de Piura (como en piuratransporta.com).
enum TipoServicio {
  urbana('Urbana', 'Urbanas'),
  regulada('Regulada', 'Reguladas'),
  interurbana('Interurbana', 'Interurbanas');

  const TipoServicio(this.valor, this.plural);

  /// Texto de `Ruta.tipoServicio`.
  final String valor;

  /// Texto del filtro.
  final String plural;

  static TipoServicio? de(Ruta ruta) {
    for (final tipo in values) {
      if (tipo.valor == ruta.tipoServicio) return tipo;
    }
    return null;
  }
}

/// Una línea que coincide con la búsqueda y, si coincidió por uno de los
/// lugares por los que pasa, cuál ("Pasa por Mercado Modelo").
class RutaFiltrada {
  const RutaFiltrada(this.ruta, {this.lugarCoincidente});

  final Ruta ruta;
  final String? lugarCoincidente;
}

/// Texto sin tildes, mayúsculas ni signos, con las palabras separadas por un
/// espacio.
String _plano(String texto) =>
    normalizar(texto).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Datos propios de la línea donde se busca (sin los lugares por los que
/// pasa). El código va también sin guion: "rd05" encuentra "RD-05".
String _textoDeLaLinea(Ruta r) => _plano(
  [
    r.codigo,
    r.codigo?.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''),
    r.nombre,
    r.empresa,
    r.puntoInicio,
    r.puntoFinal,
    r.descripcion,
    r.tipoServicio,
  ].whereType<String>().join(' '),
);

/// Líneas que coinciden con [consulta] (cada palabra escrita debe estar en
/// los datos de la línea o en los lugares por los que pasa, sin importar
/// tildes ni mayúsculas) y con [tipo], si se indica. Primero las que están
/// en servicio; por lo demás, en el orden de [rutas].
List<RutaFiltrada> filtrarRutas(
  List<Ruta> rutas, {
  String consulta = '',
  TipoServicio? tipo,
}) {
  final palabras = [
    for (final p in _plano(consulta).split(' '))
      if (p.isNotEmpty) p,
  ];
  final resultado = <RutaFiltrada>[];
  for (final ruta in rutas) {
    if (tipo != null && TipoServicio.de(ruta) != tipo) continue;
    if (palabras.isEmpty) {
      resultado.add(RutaFiltrada(ruta));
      continue;
    }
    final linea = _textoDeLaLinea(ruta);
    final lugares = [for (final l in ruta.lugaresDestacados) (l, _plano(l))];
    final todo = '$linea ${lugares.map((l) => l.$2).join(' ')}';
    if (!palabras.every(todo.contains)) continue;
    // Si los datos de la línea no bastan, coincidió por un lugar: se dice
    // cuál.
    String? lugar;
    if (!palabras.every(linea.contains)) {
      for (final (nombre, plano) in lugares) {
        if (palabras.any(plano.contains)) {
          lugar = nombre;
          break;
        }
      }
    }
    resultado.add(RutaFiltrada(ruta, lugarCoincidente: lugar));
  }
  // Primero las que están en servicio, sin cambiar el orden entre ellas.
  return [
    ...resultado.where((r) => r.ruta.activa),
    ...resultado.where((r) => !r.ruta.activa),
  ];
}

/// Cuántas líneas hay de cada tipo (la clave null es el total), para los
/// filtros.
Map<TipoServicio?, int> contarPorTipo(List<Ruta> rutas) {
  final cuenta = <TipoServicio?, int>{null: rutas.length};
  for (final tipo in TipoServicio.values) {
    cuenta[tipo] = rutas.where((r) => TipoServicio.de(r) == tipo).length;
  }
  return cuenta;
}
