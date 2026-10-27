import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dónde se guarda la sesión entre aperturas de la app (token, correo e
/// identificador del dispositivo). Es una interfaz para poder probar el
/// AuthService sin el almacenamiento real del dispositivo.
abstract class AlmacenSesion {
  Future<String?> leer(String clave);
  Future<void> guardar(String clave, String valor);
  Future<void> borrar(String clave);
}

/// Guarda la sesión solo mientras la app está abierta (pruebas y modo demo).
class AlmacenSesionMemoria implements AlmacenSesion {
  final _datos = <String, String>{};

  @override
  Future<String?> leer(String clave) async => _datos[clave];

  @override
  Future<void> guardar(String clave, String valor) async =>
      _datos[clave] = valor;

  @override
  Future<void> borrar(String clave) async => _datos.remove(clave);
}

/// Guarda la sesión cifrada en el dispositivo con flutter_secure_storage
/// (Keystore en Android; en la web, cifrado en el almacenamiento del
/// navegador). Si el almacenamiento falla, la app sigue sin sesión guardada.
class AlmacenSesionSegura implements AlmacenSesion {
  AlmacenSesionSegura([FlutterSecureStorage? almacen])
    : _almacen = almacen ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacen;

  @override
  Future<String?> leer(String clave) async {
    try {
      return await _almacen.read(key: clave);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> guardar(String clave, String valor) async {
    try {
      await _almacen.write(key: clave, value: valor);
    } catch (_) {
      // Sin almacenamiento disponible: la sesión dura solo esta apertura.
    }
  }

  @override
  Future<void> borrar(String clave) async {
    try {
      await _almacen.delete(key: clave);
    } catch (_) {}
  }
}
