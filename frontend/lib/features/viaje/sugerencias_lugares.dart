import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/lugares/buscador_lugares.dart';
import '../../data/lugares/indice_lugares.dart';
import '../../data/models/lugar.dart';

/// Letras desde las que se busca también en línea.
const minimoLetrasEnLinea = 2;

/// Espera tras la última tecla antes de buscar en línea: así no se hace una
/// petición por cada letra.
const esperaBusquedaEnLinea = Duration(milliseconds: 300);

/// Pausa sin pedir nada después de que el servicio responde 429.
const pausaTrasLimite = Duration(seconds: 5);

/// Sugerencias del buscador "¿A dónde vas?" mientras se escribe:
/// - Desde la 1.ª letra, al instante, los lugares locales (paraderos).
/// - Desde la 2.ª, además, los del buscador en línea, 300 ms después de la
///   última tecla.
///
/// Guarda cada respuesta por texto, ignora las que llegan tarde (de un texto
/// anterior) y, si el servicio falla, deja los locales y avisa con [fallo].
/// Tras un 429 no pide nada durante [pausaTrasLimite]; nunca reintenta solo.
class SugerenciasLugares extends ChangeNotifier {
  SugerenciasLugares({
    required List<Lugar> Function(String texto) locales,
    this.buscador,
  }) : _sugerirLocales = locales;

  final List<Lugar> Function(String texto) _sugerirLocales;

  /// Buscador en línea; sin él solo hay sugerencias locales.
  final BuscadorLugares? buscador;

  final _cache = <String, List<Lugar>>{};
  Timer? _espera;
  Timer? _pausa;
  int _consulta = 0;
  bool _cerrado = false;

  String _texto = '';
  List<Lugar> _locales = const [];
  List<Lugar> _otros = const [];
  bool _buscando = false;
  bool _fallo = false;
  int? _resaltado;

  /// Atribución del buscador en línea, o null si no hay.
  String? get atribucion => buscador?.atribucion;

  List<Lugar> get locales => _locales;

  /// Lugares del buscador en línea que no están entre los locales.
  List<Lugar> get otros => _otros;

  /// Locales y otros, en el orden en que se muestran (para las flechas).
  List<Lugar> get todas => [..._locales, ..._otros];

  /// Indica si para el texto actual se busca también en línea.
  bool get buscaEnLinea =>
      buscador != null && _clave(_texto).length >= minimoLetrasEnLinea;

  /// Hay una búsqueda en línea pendiente o en curso.
  bool get buscando => _buscando;

  /// La última búsqueda en línea falló (sin red, error o límite de uso).
  bool get fallo => _fallo;

  /// Posición en [todas] de la sugerencia resaltada con las flechas.
  int? get resaltado => _resaltado;

  /// Texto que identifica una consulta: sin tildes, mayúsculas ni signos, y
  /// con las abreviaturas completas ("Jr. Ica" y "jirón ica" son iguales).
  static String _clave(String texto) =>
      normalizar(expandirAbreviaturas(texto))
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .trim();

  void consultar(String texto) {
    _texto = texto;
    _resaltado = null;
    _consulta++;
    _espera?.cancel();
    _locales = _sugerirLocales(texto);
    _otros = const [];
    _buscando = false;
    _fallo = false;
    if (buscaEnLinea) {
      final clave = _clave(texto);
      final guardado = _cache[clave];
      if (guardado != null) {
        _otros = _sinRepetir(guardado);
      } else if (_pausa != null) {
        _fallo = true;
      } else {
        _buscando = true;
        final consulta = _consulta;
        _espera = Timer(
          esperaBusquedaEnLinea,
          () => _buscarEnLinea(texto, clave, consulta),
        );
      }
    }
    _avisar();
  }

  Future<void> _buscarEnLinea(String texto, String clave, int consulta) async {
    try {
      final lugares = await buscador!.buscar(texto);
      _cache[clave] = lugares;
      if (consulta != _consulta) return;
      _otros = _sinRepetir(lugares);
    } on BusquedaLugaresException catch (e) {
      if (e.limiteExcedido) _pausar();
      if (consulta != _consulta) return;
      _fallo = true;
    } catch (_) {
      if (consulta != _consulta) return;
      _fallo = true;
    }
    _buscando = false;
    _avisar();
  }

  void _pausar() {
    _pausa?.cancel();
    _pausa = Timer(pausaTrasLimite, () => _pausa = null);
  }

  /// Quita los lugares en línea que ya salen entre los locales (mismo
  /// nombre) y los repetidos (mismo nombre y detalle).
  List<Lugar> _sinRepetir(List<Lugar> lugares) {
    final vistos = {for (final l in _locales) normalizar(l.nombre)};
    final repetidos = <String>{};
    return [
      for (final l in lugares)
        if (!vistos.contains(normalizar(l.nombre)) &&
            repetidos.add('${normalizar(l.nombre)}|${l.detalle}'))
          l,
    ];
  }

  /// Mueve el resaltado (+1 abajo, -1 arriba), sin salirse de la lista.
  void moverResaltado(int paso) {
    final total = todas.length;
    if (total == 0) return;
    final actual = _resaltado;
    _resaltado = actual == null
        ? (paso > 0 ? 0 : total - 1)
        : (actual + paso).clamp(0, total - 1);
    _avisar();
  }

  /// Lugar que elige Enter: el resaltado o, si no hay, el primero.
  Lugar? elegirConEnter() {
    final lista = todas;
    final i = _resaltado;
    if (i != null && i < lista.length) return lista[i];
    return lista.firstOrNull;
  }

  /// Borra las sugerencias y cancela la búsqueda pendiente.
  void limpiar() {
    _texto = '';
    _consulta++;
    _espera?.cancel();
    _locales = const [];
    _otros = const [];
    _buscando = false;
    _fallo = false;
    _resaltado = null;
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _espera?.cancel();
    _pausa?.cancel();
    super.dispose();
  }
}
