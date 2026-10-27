import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/eta.dart';
import '../models/paradero.dart';
import '../models/ruta.dart';
import '../rutas_repository.dart';
import 'auth_service.dart';

/// Repositorio de rutas que consume la API REST de Spring Boot.
/// Si el backend no está disponible o falla la red, conmuta automáticamente
/// al [fallback] (por defecto [FakeRutasRepository]) para que la aplicación
/// siga funcionando en modo demostración.
///
/// Los ids de las rutas en el backend no son los mismos que en los datos
/// locales: para usar el trazado oficial o los paraderos locales de una ruta
/// se busca la misma línea por su código (RD-12, I-18...).
class HttpRutasRepository implements RutasRepository, FuenteEta {
  HttpRutasRepository({
    http.Client? cliente,
    Uri? baseUrl,
    required this.authService,
    this.fallback = const FakeRutasRepository(),
  }) : _cliente = cliente ?? http.Client(),
       _baseUrl = baseUrl ?? Uri.parse('http://localhost:8080');

  final http.Client _cliente;
  final Uri _baseUrl;
  final AuthService authService;
  final RutasRepository fallback;

  bool _usandoFallback = false;

  /// Código de cada ruta según el último listado (id -> código).
  final _codigos = <int, String>{};

  @override
  bool get esDemostracion => _usandoFallback;

  @override
  Future<List<Ruta>> listar() async {
    try {
      final token = await authService.obtenerToken();
      final url = _baseUrl.replace(path: '/api/rutas');

      final respuesta = await _cliente.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (respuesta.statusCode == 200) {
        final listaJson = jsonDecode(respuesta.body) as List<dynamic>;
        final rutas = listaJson
            .map((j) => Ruta.fromJson(j as Map<String, dynamic>))
            .toList();

        if (rutas.isNotEmpty) {
          _usandoFallback = false;
          _recordarCodigos(rutas);
          return rutas;
        }
      }
    } catch (_) {
      // Error de red, caída del backend o timeout
    }

    _usandoFallback = true;
    final locales = await fallback.listar();
    _recordarCodigos(locales);
    return locales;
  }

  void _recordarCodigos(List<Ruta> rutas) {
    _codigos
      ..clear()
      ..addEntries([
        for (final r in rutas)
          if (r.codigo != null) MapEntry(r.idRuta, r.codigo!),
      ]);
  }

  /// Id en los datos locales ([fallback]) de la misma línea, o null si no se
  /// sabe su código.
  Future<int?> _idLocal(int idRuta) async {
    if (_usandoFallback) return idRuta;
    final codigo = _codigos[idRuta];
    if (codigo == null) return null;
    for (final r in await fallback.listar()) {
      if (r.codigo == codigo) return r.idRuta;
    }
    return null;
  }

  @override
  Future<List<Paradero>> paraderos(int idRuta) async {
    try {
      final token = await authService.obtenerToken();
      final url = _baseUrl.replace(path: '/api/rutas/$idRuta/paraderos');

      final respuesta = await _cliente.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (respuesta.statusCode == 200) {
        final listaJson = jsonDecode(respuesta.body) as List<dynamic>;
        final paraderos = listaJson
            .map((j) => Paradero.fromJson(j as Map<String, dynamic>))
            .toList();

        if (paraderos.isNotEmpty) {
          return paraderos;
        }
      }
    } catch (_) {
      // Error de red
    }

    final local = await _idLocal(idRuta);
    return local == null ? const <Paradero>[] : fallback.paraderos(local);
  }

  /// El backend no guarda el trazado: se usa el trazado oficial local de la
  /// misma línea (buscada por código), o ninguno.
  @override
  Future<List<LatLng>> trazado(int idRuta) async {
    final local = await _idLocal(idRuta);
    return local == null ? const <LatLng>[] : fallback.trazado(local);
  }

  /// Envía un reporte GPS al backend durante el viaje en vivo.
  Future<bool> reportarGps({
    required int idRuta,
    required double latitud,
    required double longitud,
  }) async {
    try {
      final token = await authService.obtenerToken();
      final url = _baseUrl.replace(path: '/api/reportes-gps');

      final respuesta = await _cliente.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'idRuta': idRuta,
          'latitud': latitud,
          'longitud': longitud,
        }),
      );

      return respuesta.statusCode == 200 || respuesta.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// ETA de la próxima unidad según el backend: minutos y si es una
  /// estimación (origen SIMULADO, sin pasajeros compartiendo el GPS).
  @override
  Future<Eta?> eta(int idRuta) async {
    try {
      final token = await authService.obtenerToken();
      final url = _baseUrl.replace(path: '/api/reportes-gps/eta/$idRuta');

      final respuesta = await _cliente.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (respuesta.statusCode == 200) {
        return Eta.fromJson(jsonDecode(respuesta.body) as Map<String, dynamic>);
      }
    } catch (_) {
      // Error de red o respuesta inesperada.
    }
    return null;
  }
}
