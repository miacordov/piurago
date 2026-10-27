import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'almacen_sesion.dart';

/// Servicio de autenticación con el backend de PiuraGo.
/// Administra tokens JWT tanto para usuarios anónimos (por device UUID) como
/// para usuarios registrados (email y contraseña).
///
/// La sesión (token, correo e identificador del dispositivo) se guarda en un
/// [AlmacenSesion]: al volver a abrir la app, [restaurarSesion] la recupera y
/// no se crea un usuario anónimo nuevo en cada apertura.
class AuthService {
  AuthService({
    http.Client? cliente,
    Uri? baseUrl,
    String? deviceUuidInicial,
    AlmacenSesion? almacen,
  }) : _cliente = cliente ?? http.Client(),
       _baseUrl = baseUrl ?? Uri.parse('http://localhost:8080'),
       _almacen = almacen ?? AlmacenSesionMemoria(),
       _deviceUuid = deviceUuidInicial ?? _generarDeviceUuid();

  static const _claveToken = 'piurago.token';
  static const _claveEmail = 'piurago.email';
  static const _claveDispositivo = 'piurago.deviceUuid';

  final http.Client _cliente;
  final Uri _baseUrl;
  final AlmacenSesion _almacen;
  String _deviceUuid;

  String? _token;
  String? _email;
  bool _ultimoFalloFueDeRed = false;

  bool get estaAutenticado => _token != null;

  /// Hay una sesión de usuario registrado (no solo el token anónimo).
  bool get esRegistrado => _token != null && _email != null;
  String? get emailActual => _email;
  String? get tokenActual => _token;
  String get deviceUuid => _deviceUuid;

  /// El último login o registro falló por la red (servidor caído o sin
  /// conexión), no por los datos que se enviaron.
  bool get ultimoFalloFueDeRed => _ultimoFalloFueDeRed;

  /// Recupera la sesión guardada. Si es la primera apertura, guarda el
  /// identificador del dispositivo para reutilizarlo después.
  Future<void> restaurarSesion() async {
    final dispositivo = await _almacen.leer(_claveDispositivo);
    if (dispositivo != null) {
      _deviceUuid = dispositivo;
    } else {
      await _almacen.guardar(_claveDispositivo, _deviceUuid);
    }
    _token = await _almacen.leer(_claveToken);
    _email = await _almacen.leer(_claveEmail);
  }

  /// Obtiene el token JWT actual o solicita uno anónimo si no existe.
  Future<String?> obtenerToken() async {
    if (_token != null) return _token;

    try {
      final url = _baseUrl.replace(path: '/api/usuarios/anonimo');
      final respuesta = await _cliente.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceUuid': _deviceUuid, 'tipoDispositivo': 'WEB'}),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        await _guardarSesion(datos['token'] as String?, null);
        return _token;
      }
    } catch (_) {
      // Si el backend no está disponible, se maneja como offline.
    }
    return null;
  }

  /// Inicia sesión con credenciales registradas.
  Future<bool> login(String email, String password) => _acceder(
    '/api/auth/login',
    {'email': email, 'password': password},
    email,
  );

  /// Registra un nuevo usuario en el sistema.
  Future<bool> registrar(String nombre, String email, String password) =>
      _acceder('/api/auth/registro', {
        'nombre': nombre,
        'email': email,
        'password': password,
      }, email);

  Future<bool> _acceder(
    String ruta,
    Map<String, String> cuerpo,
    String email,
  ) async {
    _ultimoFalloFueDeRed = false;
    try {
      final respuesta = await _cliente.post(
        _baseUrl.replace(path: ruta),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cuerpo),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        await _guardarSesion(
          datos['token'] as String?,
          datos['email'] as String? ?? email,
        );
        return true;
      }
      // 5xx: el servidor no pudo atender, no es culpa de los datos.
      _ultimoFalloFueDeRed = respuesta.statusCode >= 500;
    } catch (_) {
      _ultimoFalloFueDeRed = true;
    }
    return false;
  }

  Future<void> _guardarSesion(String? token, String? email) async {
    _token = token;
    _email = email;
    if (token == null) return;
    await _almacen.guardar(_claveToken, token);
    if (email != null) {
      await _almacen.guardar(_claveEmail, email);
    } else {
      await _almacen.borrar(_claveEmail);
    }
  }

  /// Cierra la sesión: borra el token y el correo (también los guardados),
  /// pero conserva el identificador del dispositivo.
  Future<void> cerrarSesion() async {
    _token = null;
    _email = null;
    await _almacen.borrar(_claveToken);
    await _almacen.borrar(_claveEmail);
  }

  /// Cierra la sesión activa y elimina el token en memoria.
  void logout() {
    cerrarSesion();
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
