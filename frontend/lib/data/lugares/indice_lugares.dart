import '../models/lugar.dart';

/// Búsqueda por nombre entre lugares conocidos (los paraderos y el buscador
/// de prueba): compara sin tildes ni mayúsculas y entiende abreviaturas.

/// Cantidad máxima de sugerencias del autocompletado.
const maximoSugerencias = 6;

/// Texto en minúsculas y sin tildes, para comparar nombres.
String normalizar(String texto) {
  const conTilde = 'áàäâéèëêíìïîóòöôúùüûñ';
  const sinTilde = 'aaaaeeeeiiiioooouuuun';
  final buffer = StringBuffer();
  for (final letra in texto.trim().toLowerCase().split('')) {
    final i = conTilde.indexOf(letra);
    buffer.write(i < 0 ? letra : sinTilde[i]);
  }
  return buffer.toString();
}

/// Formas cortas de las palabras de las direcciones de Piura: así "jr" o
/// "jr." encuentran "Jirón" y "av" encuentra "Avenida".
const _abreviaturas = {
  'avenida': 'av',
  'avda': 'av',
  'jiron': 'jr',
  'pasaje': 'psje',
  'pje': 'psje',
  'pj': 'psje',
  'calle': 'ca',
  'cl': 'ca',
  'carretera': 'carr',
  'prolongacion': 'prol',
  'urbanizacion': 'urb',
  'asentamiento': 'aa',
  'humano': 'hh',
  'universidad': 'univ',
  'malecon': 'mlc',
};

/// Palabras del texto, en minúsculas, sin tildes ni signos.
List<String> _palabras(String texto) =>
    normalizar(texto)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((p) => p.isNotEmpty)
        .toList();

List<String> _abreviadas(List<String> palabras) => [
  for (final p in palabras) _abreviaturas[p] ?? p,
];

/// Qué tan bien coinciden las palabras de un nombre con las de la consulta:
/// 0 si el nombre empieza con lo escrito, 1 si cada palabra escrita es el
/// comienzo de una palabra del nombre, 2 si lo contiene; null si no coincide.
int? _coincidencia(_Forma nombre, _Forma consulta) {
  if (nombre.texto.startsWith(consulta.texto)) return 0;
  if (consulta.palabras.every(
    (q) => nombre.palabras.any((n) => n.startsWith(q)),
  )) {
    return 1;
  }
  if (nombre.texto.contains(consulta.texto)) return 2;
  return null;
}

/// Palabras de un texto y el texto que forman, unidas por espacios.
class _Forma {
  _Forma(this.palabras) : texto = palabras.join(' ');

  final List<String> palabras;
  final String texto;
}

/// Catálogo preparado para sugerir lugares mientras se escribe: las
/// palabras de cada nombre (tal cual y abreviadas) se calculan una sola vez.
class IndiceLugares {
  IndiceLugares(this.lugares)
    : _formas = [
        for (final l in lugares)
          [
            _Forma(_palabras(l.nombre)),
            _Forma(_abreviadas(_palabras(l.nombre))),
          ],
      ];

  final List<Lugar> lugares;
  final List<List<_Forma>> _formas;

  /// Lugares que coinciden con [consulta], como máximo [maximoSugerencias]:
  /// primero los que empiezan con lo escrito, luego los que tienen cada
  /// palabra escrita y al final los que solo la contienen. A igual
  /// coincidencia, en el orden del catálogo (paraderos primero y luego las
  /// calles más importantes). Compara las palabras tal cual y abreviadas:
  /// "jir" y "jr" encuentran "Jirón".
  List<Lugar> sugerir(String consulta) {
    final palabras = _palabras(consulta);
    if (palabras.isEmpty) return const [];
    final consultas = [_Forma(palabras), _Forma(_abreviadas(palabras))];
    final encontrados = <(int, int)>[];
    for (final (i, formas) in _formas.indexed) {
      int? mejor;
      for (final nombre in formas) {
        for (final q in consultas) {
          final puntaje = _coincidencia(nombre, q);
          if (puntaje != null && (mejor == null || puntaje < mejor)) {
            mejor = puntaje;
          }
        }
      }
      if (mejor != null) encontrados.add((mejor, i));
    }
    encontrados.sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    return [for (final e in encontrados.take(maximoSugerencias)) lugares[e.$2]];
  }
}

/// Sugerencias de [catalogo] para [consulta] (ver [IndiceLugares.sugerir]).
List<Lugar> sugerirLugares(List<Lugar> catalogo, String consulta) =>
    IndiceLugares(catalogo).sugerir(consulta);
