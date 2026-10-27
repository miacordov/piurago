import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Descarga el archivo en el navegador con un enlace temporal.
Future<bool> guardarArchivo({
  required String nombre,
  required Uint8List bytes,
  required String tipo,
}) async {
  try {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: tipo));
    final url = web.URL.createObjectURL(blob);
    final enlace = web.HTMLAnchorElement()
      ..href = url
      ..download = nombre;
    enlace.style.display = 'none';
    web.document.body?.append(enlace);
    enlace.click();
    enlace.remove();
    web.URL.revokeObjectURL(url);
    return true;
  } catch (_) {
    return false;
  }
}
