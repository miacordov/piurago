import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:piurago/data/lugares/buscador_lugares.dart';
import 'package:piurago/data/models/lugar.dart';
import 'package:piurago/features/viaje/sugerencias_lugares.dart';

import 'repositorio_prueba.dart';

const locales = [
  Lugar('Mercado Central', LatLng(-5.2010, -80.63), tipo: TipoLugar.paradero),
  Lugar('Hospital Sur', LatLng(-5.2190, -80.63), tipo: TipoLugar.paradero),
];

List<Lugar> sugerirLocales(String texto) => [
  for (final l in locales)
    if (texto.trim().isNotEmpty &&
        l.nombre.toLowerCase().contains(texto.trim().toLowerCase()))
      l,
];

SugerenciasLugares crear(BuscadorLugares? buscador) =>
    SugerenciasLugares(locales: sugerirLocales, buscador: buscador);

void main() {
  test('desde la 1.ª letra salen los locales, sin pedir nada en línea', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso();
      final s = crear(buscador)..consultar('m');
      async.elapse(const Duration(seconds: 1));

      expect(s.locales.map((l) => l.nombre), ['Mercado Central']);
      expect(s.buscaEnLinea, isFalse);
      expect(buscador.pedidos, isEmpty);
    });
  });

  test('desde la 2.ª letra busca en línea 300 ms después de la última '
      'tecla', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso();
      final s = crear(buscador)
        ..consultar('me')
        ..consultar('mer');
      expect(s.buscaEnLinea, isTrue);
      expect(s.buscando, isTrue);

      async.elapse(const Duration(milliseconds: 299));
      expect(buscador.pedidos, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(buscador.pedidos, ['mer']);
      expect(s.buscando, isFalse);
      expect(s.otros.map((l) => l.nombre), ['Resultado de mer']);
    });
  });

  test('ignora las respuestas que llegan tarde', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso();
      final primera = Completer<List<Lugar>>();
      buscador.respuestas['real'] = primera.future;
      final s = crear(buscador)..consultar('real');
      async.elapse(const Duration(milliseconds: 300));

      s.consultar('realp');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(s.otros.map((l) => l.nombre), ['Resultado de realp']);

      primera.complete([const Lugar('Viejo', LatLng(0, 0))]);
      async.flushMicrotasks();
      expect(s.otros.map((l) => l.nombre), ['Resultado de realp']);
    });
  });

  test('guarda cada respuesta: el mismo texto no se vuelve a pedir', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso();
      final s = crear(buscador)..consultar('jr ica');
      async.elapse(const Duration(milliseconds: 300));
      s.consultar('jr ic');
      async.elapse(const Duration(milliseconds: 300));
      // "JR. Ica" es el mismo texto que "jr ica" (sin signos ni mayúsculas).
      s.consultar('JR. Ica');
      expect(s.buscando, isFalse);
      async.elapse(const Duration(seconds: 1));

      expect(buscador.pedidos, ['jr ica', 'jr ic']);
      expect(s.otros.map((l) => l.nombre), ['Resultado de jr ica']);
    });
  });

  test('si falla la red, deja los locales y avisa', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso()..fallar = true;
      final s = crear(buscador)..consultar('mercado');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();

      expect(s.fallo, isTrue);
      expect(s.buscando, isFalse);
      expect(s.otros, isEmpty);
      expect(s.locales.map((l) => l.nombre), ['Mercado Central']);

      // Un fallo no se guarda: al escribir de nuevo se vuelve a intentar.
      buscador.fallar = false;
      s.consultar('mercad');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(s.fallo, isFalse);
      expect(buscador.pedidos, ['mercado', 'mercad']);
    });
  });

  test('tras un 429 no pide nada durante 5 segundos', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso()..limite = true;
      final s = crear(buscador)..consultar('piura');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(s.fallo, isTrue);

      buscador.limite = false;
      s.consultar('piur');
      async.elapse(const Duration(seconds: 2));
      expect(buscador.pedidos, ['piura']);
      expect(s.fallo, isTrue);

      async.elapse(const Duration(seconds: 3));
      s.consultar('piu');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(buscador.pedidos, ['piura', 'piu']);
      expect(s.fallo, isFalse);
    });
  });

  test('no repite en "Otros lugares" lo que ya está entre los locales', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso();
      buscador.respuestas['hospital'] = Future.value([
        const Lugar('HOSPITAL SUR', LatLng(-5.2191, -80.63)),
        const Lugar('Hospital Norte', LatLng(-5.18, -80.63)),
      ]);
      final s = crear(buscador)..consultar('hospital');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();

      expect(s.locales.map((l) => l.nombre), ['Hospital Sur']);
      expect(s.otros.map((l) => l.nombre), ['Hospital Norte']);
    });
  });

  test('las flechas recorren locales y otros; Enter elige el resaltado', () {
    fakeAsync((async) {
      final s = crear(BuscadorFalso())..consultar('mercado');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(s.todas.map((l) => l.nombre), [
        'Mercado Central',
        'Resultado de mercado',
      ]);
      // Sin resaltar, Enter elige la primera.
      expect(s.elegirConEnter()!.nombre, 'Mercado Central');

      s.moverResaltado(1);
      expect(s.resaltado, 0);
      s.moverResaltado(1);
      expect(s.resaltado, 1);
      s.moverResaltado(1);
      expect(s.resaltado, 1);
      expect(s.elegirConEnter()!.nombre, 'Resultado de mercado');
      s.moverResaltado(-1);
      expect(s.resaltado, 0);
    });
  });

  test('si la base ya da 5 sugerencias no pide nada en línea', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso();
      final s = SugerenciasLugares(
        locales: (texto) => [
          for (var i = 0; i < 5; i++) Lugar('Calle $i', const LatLng(0, 0)),
        ],
        buscador: buscador,
      )..consultar('calle');
      async.elapse(const Duration(seconds: 1));

      expect(s.buscaEnLinea, isFalse);
      expect(buscador.pedidos, isEmpty);
      expect(s.todas, hasLength(5));
    });
  });

  test('los lugares en línea solo completan hasta 5', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso();
      buscador.respuestas['hospital'] = Future.value([
        for (var i = 0; i < 6; i++)
          Lugar('Hospital $i', const LatLng(-5.18, -80.63)),
      ]);
      final s = crear(buscador)..consultar('hospital');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();

      expect(s.locales, hasLength(1));
      expect(s.otros, hasLength(4));
    });
  });

  test('sin buscador en línea solo hay locales', () {
    fakeAsync((async) {
      final s = crear(null)..consultar('mercado');
      async.elapse(const Duration(seconds: 1));
      expect(s.buscaEnLinea, isFalse);
      expect(s.locales, hasLength(1));
    });
  });

  test('limpiar cancela la búsqueda pendiente', () {
    fakeAsync((async) {
      final buscador = BuscadorFalso();
      final s = crear(buscador)
        ..consultar('mercado')
        ..limpiar();
      async.elapse(const Duration(seconds: 1));

      expect(buscador.pedidos, isEmpty);
      expect(s.todas, isEmpty);
      expect(s.buscaEnLinea, isFalse);
    });
  });
}
