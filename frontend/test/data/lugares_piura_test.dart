import 'package:flutter_test/flutter_test.dart';
import 'package:piurago/data/lugares/indice_lugares.dart';
import 'package:piurago/data/lugares/lugares_piura.dart';
import 'package:piurago/data/models/lugar.dart';

/// Prueba de aceptación con la base propia de Piura (sin internet): lo que
/// escribe un piurano y lo que debe salir entre las primeras sugerencias.
void main() {
  final indice = IndiceLugares(lugaresPiura);

  const casos = {
    'jr lima': 'Calle Lima',
    'calle lima': 'Calle Lima',
    'jr tacna': 'Calle Tacna',
    'jr libertad': 'Calle Libertad',
    'jr ayacucho': 'Calle Ayacucho',
    'jr callao': 'Calle Callao',
    'jr arequipa': 'Calle Arequipa',
    'jr huancavelica': 'Calle Huancavelica',
    'av grau': 'Avenida Grau',
    'av sanchez cerro': 'Avenida Sánchez Cerro',
    'av sánchez cerro': 'Avenida Sánchez Cerro',
    'av loreto': 'Avenida Loreto',
    'av bolognesi': 'Avenida Bolognesi',
    'av guardia civil': 'Avenida Guardia Civil',
    'av country': 'Avenida Country',
    'av vice': 'Avenida Vice',
    'av cayetano heredia': 'Avenida Cayetano Heredia',
    'av los tallanes': 'Avenida Los Tallanes',
    'av circunvalacion': 'Avenida Circunvalación',
    'av ramon castilla': 'Avenida Ramón Castilla',
    'panamericana': 'Carretera Panamericana Norte',
  };

  for (final MapEntry(key: consulta, value: esperado) in casos.entries) {
    test('"$consulta" sugiere "$esperado"', () {
      final nombres = indice.sugerir(consulta).map((l) => l.nombre).toList();
      expect(nombres, contains(esperado));
      expect(nombres.indexOf(esperado), lessThan(3), reason: '$nombres');
    });
  }

  test('las sugerencias de calles dicen dónde quedan', () {
    final lima = indice.sugerir('jr lima').first;
    expect(lima.tipo, TipoLugar.calle);
    expect(lima.detalle, isNotEmpty);
  });

  test('buscar en la base es rápido (menos de 10 ms por tecla)', () {
    const teclas = ['j', 'jr', 'jr ', 'jr l', 'jr li', 'jr lim'];
    // Calentamiento: la primera vuelta incluye la compilación del código.
    for (var i = 0; i < 3; i++) {
      teclas.forEach(indice.sugerir);
    }
    final reloj = Stopwatch()..start();
    for (var i = 0; i < 5; i++) {
      teclas.forEach(indice.sugerir);
    }
    expect(reloj.elapsedMilliseconds / (5 * teclas.length), lessThan(10));
  });
}
