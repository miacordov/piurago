import 'package:flutter/foundation.dart';

import '../models/lugar.dart';

/// Búsqueda por nombre entre lugares conocidos (los paraderos y la base
/// propia de Piura): compara sin tildes ni mayúsculas y entiende
/// abreviaturas.

/// Cantidad máxima de sugerencias del autocompletado (como piuratransporta).
const maximoSugerencias = 5;

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
/// "jr." encuentran "Jirón" y "av" encuentra "Avenida". En Piura la gente
/// dice "jirón" o "calle" para la misma vía (el Jr. Lima del centro es
/// "Calle Lima" en OpenStreetMap), así que las dos valen lo mismo.
const _abreviaturas = {
  'avenida': 'av',
  'avda': 'av',
  'jiron': 'ca',
  'jr': 'ca',
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

/// Formas de un nombre para comparar: tal cual y con las abreviaturas (una
/// sola si son iguales), y todo su texto junto para descartar rápido.
class _Nombre {
  factory _Nombre(String nombre) {
    final tal = _Forma(_palabras(nombre));
    final cortas = _Forma(_abreviadas(tal.palabras));
    final formas = cortas.texto == tal.texto ? [tal] : [tal, cortas];
    return _Nombre._(formas, formas.map((f) => f.texto).join(' '));
  }

  const _Nombre._(this.formas, this.todo);

  final List<_Forma> formas;
  final String todo;
}

/// Catálogo preparado para sugerir lugares mientras se escribe: las
/// palabras de cada nombre (tal cual y abreviadas) se calculan una sola vez.
class IndiceLugares {
  IndiceLugares(this.lugares)
    : _nombres = [for (final l in lugares) _Nombre(l.nombre)];

  IndiceLugares._(this.lugares, this._nombres);

  /// Índice de una lista que no cambia (como la base propia de Piura): se
  /// arma la primera vez y se reutiliza al volver a abrir el mapa.
  factory IndiceLugares.de(List<Lugar> lugares) =>
      _guardados[lugares] ??= IndiceLugares(lugares);

  static final _guardados = Expando<IndiceLugares>('indices de lugares');

  /// Primero los lugares de [primero] y luego los de [despues], salvo los
  /// que [excluir] descarta. No vuelve a preparar los nombres.
  factory IndiceLugares.unir(
    IndiceLugares primero,
    IndiceLugares despues, {
    bool Function(Lugar lugar)? excluir,
  }) {
    final lugares = [...primero.lugares];
    final nombres = [...primero._nombres];
    for (final (i, lugar) in despues.lugares.indexed) {
      if (excluir != null && excluir(lugar)) continue;
      lugares.add(lugar);
      nombres.add(despues._nombres[i]);
    }
    return IndiceLugares._(lugares, nombres);
  }

  final List<Lugar> lugares;
  final List<_Nombre> _nombres;

  /// Lugares que coinciden con [consulta], como máximo [maximoSugerencias]:
  /// primero los que empiezan con lo escrito, luego los que tienen cada
  /// palabra escrita y al final los que solo la contienen. A igual
  /// coincidencia, en el orden del catálogo (paraderos primero y luego las
  /// calles más importantes). Compara las palabras tal cual y abreviadas:
  /// "jir" y "jr" encuentran "Jirón".
  List<Lugar> sugerir(String consulta) => _sugerir(consulta, descartar: true);

  /// Igual que [sugerir], sin el descarte rápido (para probar que da lo
  /// mismo).
  @visibleForTesting
  List<Lugar> sugerirSinDescarte(String consulta) =>
      _sugerir(consulta, descartar: false);

  List<Lugar> _sugerir(String consulta, {required bool descartar}) {
    final palabras = _palabras(consulta);
    if (palabras.isEmpty) return const [];
    final tal = _Forma(palabras);
    final cortas = _Forma(_abreviadas(palabras));
    final consultas = cortas.texto == tal.texto ? [tal] : [tal, cortas];
    final encontrados = <(int, int)>[];
    for (final (i, nombre) in _nombres.indexed) {
      // Toda coincidencia necesita que cada palabra escrita esté en el
      // nombre: con eso se descarta casi todo el catálogo de una vez.
      if (descartar &&
          !consultas.any((q) => q.palabras.every(nombre.todo.contains))) {
        continue;
      }
      int? mejor;
      for (final forma in nombre.formas) {
        for (final q in consultas) {
          final puntaje = _coincidencia(forma, q);
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
