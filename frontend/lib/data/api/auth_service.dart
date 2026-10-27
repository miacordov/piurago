import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Servicio de autenticación con el backend de PiuraGo.
/// Administra tokens JWT tanto para usuarios anónimos (por device UUID) como
/// para usuarios registrados (email y contraseña).
class AuthService {
  AuthService({
    http.Client? cliente,
    Uri? baseUrl,
    String? deviceUuidInicial,
  })  : _cliente = cliente ?? http.Client(),
        _baseUrl = baseUrl ?? Uri.parse('http://localhost:8080'),
        _deviceUuid = deviceUuidInicial ?? _generarDeviceUuid();

  final http.Client _cliente;
  final Uri _baseUrl;
  final String _deviceUuid;

  String? _token;
  String? _email;

  bool get estaAutenticado => _token != null;
  String? get emailActual => _email;
  String? get tokenActual => _token;
  String get deviceUuid => _deviceUuid;

  /// Obtiene el token JWT actual o solicita uno anónimo si no existe.
  Future<String?> obtenerToken() async {
    if (_token != null) return _token;

    try {
      final url = _baseUrl.replace(path: '/api/usuarios/anonimo');
      final respuesta = await _cliente.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceUuid': _deviceUuid,
          'tipoDispositivo': 'WEB',
        }),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        _token = datos['token'] as String?;
        return _token;
      }
    } catch (_) {
      // Si el backend no está disponible, se maneja como offline.
    }
    return null;
  }

  /// Inicia sesión con credenciales registradas.
  Future<bool> login(String email, String password) async {
    try {
      final url = _baseUrl.replace(path: '/api/auth/login');
      final respuesta = await _cliente.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        _token = datos['token'] as String?;
        _email = datos['email'] as String? ?? email;
        return true;
      }
    } catch (_) {
      // Error de red
    }
    return false;
  }

  /// Registra un nuevo usuario en el sistema.
  Future<bool> registrar(String nombre, String email, String password) async {
    try {
      final url = _baseUrl.replace(path: '/api/auth/registro');
      final respuesta = await _cliente.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
        }),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        _token = datos['token'] as String?;
        _email = datos['email'] as String? ?? email;
        return true;
      }
    } catch (_) {
      // Error de red
    }
    return false;
  }

  /// Cierra la sesión activa y elimina el token en memoria.
  void logout() {
    _token = null;
    _email = null;
  }

  /// Permite establecer el token directamente (útil para pruebas o restaurar sesión).
  void establecerTokenManualmente(String token, {String? email}) {
    _token = token;
    _email = email;
  }

  static String _generarDeviceUuid() {
    final rand = Random();
    final millis = DateTime.now().millisecondsSinceEpoch;
    final aleatorio = rand.nextInt(999999).toString().padLeft(6, '0');
    return 'piurago-dev-$millis-$aleatorio';
  }
}
