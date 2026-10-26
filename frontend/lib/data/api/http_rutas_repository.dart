import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/paradero.dart';
import '../models/ruta.dart';
import '../rutas_repository.dart';
import '../trazados_oficiales.dart';
import 'auth_service.dart';

/// Repositorio de rutas que consume la API REST de Spring Boot.
/// Si el backend no está disponible o falla la red, conmuta automáticamente
/// al [fallback] (por defecto [FakeRutasRepository]) para que la aplicación
/// siga funcionando en modo demostración.
class HttpRutasRepository implements RutasRepository {
  HttpRutasRepository({
    http.Client? cliente,
    Uri? baseUrl,
    required this.authService,
    this.fallback = const FakeRutasRepository(),
  })  : _cliente = cliente ?? http.Client(),
        _baseUrl = baseUrl ?? Uri.parse('http://localhost:8080');

  final http.Client _cliente;
  final Uri _baseUrl;
  final AuthService authService;
  final RutasRepository fallback;

  bool _usandoFallback = false;

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
          return rutas;
        }
      }
    } catch (_) {
      // Error de red, caída del backend o timeout
    }

    _usandoFallback = true;
    return fallback.listar();
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

    return fallback.paraderos(idRuta);
  }

  @override
  Future<List<LatLng>> trazado(int idRuta) async {
    // La geometría del recorrido se dibuja con los trazados oficiales
    // confirmados de Piura o en línea recta sobre los paraderos.
    return trazadosOficiales[idRuta] ?? await fallback.trazado(idRuta);
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

  /// Consulta el ETA en vivo calculado por el backend hacia el próximo paradero.
  Future<int?> obtenerEta(int idRuta) async {
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
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        return (datos['etaMinutos'] as num?)?.toInt();
      }
    } catch (_) {
      // Error de red
    }
    return null;
  }
}
