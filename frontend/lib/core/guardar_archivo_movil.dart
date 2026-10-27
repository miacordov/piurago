import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// En el celular no hay "Descargas" al alcance de la app: se abre el menú
/// de compartir para guardarlo en Archivos, Drive o enviarlo.
Future<bool> guardarArchivo({
  required String nombre,
  required Uint8List bytes,
  required String tipo,
}) async {
  try {
    final resultado = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: tipo, name: nombre)],
        fileNameOverrides: [nombre],
      ),
    );
    return resultado.status != ShareResultStatus.unavailable;
  } catch (_) {
    return false;
  }
}
