import 'dart:typed_data';

import 'guardar_archivo_movil.dart'
    if (dart.library.js_interop) 'guardar_archivo_web.dart'
    as plataforma;

/// Entrega al usuario un archivo generado por la app (por ejemplo, el Excel
/// de congestión). Se inyecta en las pantallas para poder probarlas.
abstract class GuardadorArchivos {
  /// Devuelve false si no se pudo guardar ni compartir.
  Future<bool> guardar({
    required String nombre,
    required Uint8List bytes,
    required String tipo,
  });
}

/// En el navegador descarga el archivo; en el celular abre el menú de
/// compartir (Drive, WhatsApp, Archivos...).
class GuardadorPorPlataforma implements GuardadorArchivos {
  const GuardadorPorPlataforma();

  @override
  Future<bool> guardar({
    required String nombre,
    required Uint8List bytes,
    required String tipo,
  }) => plataforma.guardarArchivo(nombre: nombre, bytes: bytes, tipo: tipo);
}
