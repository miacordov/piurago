import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../data/lugares/buscador_lugares.dart';
import 'busqueda_viaje.dart';
import 'opcion_viaje_card.dart';
import 'planificador_viaje.dart';
import 'sugerencias_lugares.dart';

/// Panel "¿A dónde vas?". Primero el destino y luego el origen: se eligen
/// con un clic, un toque o las flechas y Enter (sugerencia, lugar frecuente
/// o punto del mapa) y, con los dos, aparecen las líneas sin otro paso. Las
/// sugerencias salen de los paraderos y, desde la 2.ª letra, del buscador
/// de lugares en línea. La mejor queda elegida y se
/// dibuja en el mapa; "Iniciar viaje" abre la guía paso a paso.
class PlanificarPanel extends StatefulWidget {
  const PlanificarPanel({
    super.key,
    required this.planificador,
    this.buscadorLugares,
    this.esDemostracion = false,
  });

  final PlanificadorViaje planificador;

  /// Buscador de lugares en línea; sin él solo se sugieren los paraderos.
  final BuscadorLugares? buscadorLugares;

  /// Si es true, la guía avisa que los paraderos son propuestos.
  final bool esDemostracion;

  @override
  State<PlanificarPanel> createState() => _PlanificarPanelState();
}

class _PlanificarPanelState extends State<PlanificarPanel> {
  final _desde = TextEditingController();
  final _hasta = TextEditingController();
  late final _focoDesde = FocusNode(
    onKeyEvent: (_, evento) => _alPulsarTecla(CampoViaje.desde, evento),
  );
  late final _focoHasta = FocusNode(
    onKeyEvent: (_, evento) => _alPulsarTecla(CampoViaje.hasta, evento),
  );
  late final _sugerencias = SugerenciasLugares(
    locales: _p.sugerencias,
    buscador: widget.buscadorLugares,
  );

  PlanificadorViaje get _p => widget.planificador;

  @override
  void initState() {
    super.initState();
    _p.addListener(_sincronizarTextos);
    _focoDesde.addListener(() => _alCambiarFoco(_focoDesde, CampoViaje.desde));
    _focoHasta.addListener(() => _alCambiarFoco(_focoHasta, CampoViaje.hasta));
    _sincronizarTextos();
  }

  @override
  void dispose() {
    _p.removeListener(_sincronizarTextos);
    _desde.dispose();
    _hasta.dispose();
    _focoDesde.dispose();
    _focoHasta.dispose();
    _sugerencias.dispose();
    super.dispose();
  }

  /// Muestra en cada campo el lugar fijado (por ejemplo, un punto tocado en
  /// el mapa). Si el campo no tiene lugar, se deja lo que se está escribiendo.
  void _sincronizarTextos() {
    final origen = _p.origen;
    final destino = _p.destino;
    if (origen != null && _desde.text != origen.nombre) {
      _desde.text = origen.nombre;
    }
    if (destino != null && _hasta.text != destino.nombre) {
      _hasta.text = destino.nombre;
    }
  }

  void _alCambiarFoco(FocusNode foco, CampoViaje campo) {
    if (foco.hasFocus) {
      _p.activarCampo(campo);
      _sugerencias.consultar(
        _lugar(campo) == null ? _controlador(campo).text : '',
      );
    }
    setState(() {});
  }

  /// Flechas arriba y abajo recorren las sugerencias; Escape las cierra.
  KeyEventResult _alPulsarTecla(CampoViaje campo, KeyEvent evento) {
    if (evento is KeyUpEvent || !_sugerenciasVisibles(campo)) {
      return KeyEventResult.ignored;
    }
    switch (evento.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _sugerencias.moverResaltado(1);
      case LogicalKeyboardKey.arrowUp:
        _sugerencias.moverResaltado(-1);
      case LogicalKeyboardKey.escape:
        _sugerencias.limpiar();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  TextEditingController _controlador(CampoViaje campo) =>
      campo == CampoViaje.desde ? _desde : _hasta;

  FocusNode _foco(CampoViaje campo) =>
      campo == CampoViaje.desde ? _focoDesde : _focoHasta;

  Lugar? _lugar(CampoViaje campo) =>
      campo == CampoViaje.desde ? _p.origen : _p.destino;

  void _fijar(CampoViaje campo, Lugar? lugar) => campo == CampoViaje.desde
      ? _p.fijarOrigen(lugar)
      : _p.fijarDestino(lugar);

  void _alEscribir(CampoViaje campo, String texto) {
    // Escribir sobre un lugar elegido lo deja sin definir otra vez.
    final lugar = _lugar(campo);
    if (lugar != null && lugar.nombre != texto) _fijar(campo, null);
    _sugerencias.consultar(texto);
  }

  /// Fija el lugar y pasa al campo que falta; con los dos, cierra el teclado.
  void _elegirLugar(CampoViaje campo, Lugar lugar) {
    _sugerencias.limpiar();
    _controlador(campo).text = lugar.nombre;
    _fijar(campo, lugar);
    if (_p.destino == null) {
      _focoHasta.requestFocus();
    } else if (_p.origen == null) {
      _focoDesde.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  /// Enter elige la sugerencia resaltada o, si no hay, la primera.
  void _alEnviar(CampoViaje campo) {
    if (!_sugerenciasVisibles(campo)) return;
    final lugar = _sugerencias.elegirConEnter();
    if (lugar != null) _elegirLugar(campo, lugar);
  }

  bool _sugerenciasVisibles(CampoViaje campo) =>
      _foco(campo).hasFocus &&
      _lugar(campo) == null &&
      (_sugerencias.todas.isNotEmpty || _sugerencias.buscaEnLinea);

  void _intercambiar() {
    final texto = _desde.text;
    _desde.text = _hasta.text;
    _hasta.text = texto;
    _sugerencias.limpiar();
    _p.intercambiar();
  }

  void _limpiar() {
    _desde.clear();
    _hasta.clear();
    _sugerencias.limpiar();
    FocusScope.of(context).unfocus();
    _p.limpiar();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_p, _sugerencias]),
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_p.estado) {
            _ when _p.paso != null => _GuiaViaje(
              planificador: _p,
              esDemostracion: widget.esDemostracion,
            ),
            EstadoViaje.cargando => const _Cargando(),
            EstadoViaje.error => _Error(onReintentar: _p.reintentar),
            _ => _formulario(),
          },
        );
      },
    );
  }

  Widget _formulario() {
    final activo = _p.campoActivo;
    final indicacion = activo == CampoViaje.hasta
        ? 'Toca el mapa para fijar tu destino.'
        : 'Toca el mapa para fijar tu origen.';
    final mostrarFrecuentes =
        _p.frecuentes.isNotEmpty &&
        _lugar(activo) == null &&
        _controlador(activo).text.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titulo(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _campo(CampoViaje.hasta),
                  const SizedBox(height: 10),
                  _campo(CampoViaje.desde),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Intercambiar origen y destino',
                  onPressed: _intercambiar,
                  icon: const Icon(Icons.swap_vert, color: AppColors.text),
                ),
                IconButton(
                  tooltip: 'Limpiar',
                  onPressed: _limpiar,
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.touch_app_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                indicacion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.small,
              ),
            ),
          ],
        ),
        if (mostrarFrecuentes) ...[
          const SizedBox(height: 18),
          const Text(
            'Destinos rápidos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final lugar in _p.frecuentes)
                _Ficha(
                  key: ValueKey('frecuente-${lugar.nombre}'),
                  texto: lugar.nombre,
                  onTap: () => _elegirLugar(activo, lugar),
                ),
            ],
          ),
        ],
        ..._resultados(),
      ],
    );
  }

  Widget _campo(CampoViaje campo) {
    final esDesde = campo == CampoViaje.desde;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: ValueKey(esDesde ? 'campo-desde' : 'campo-hasta'),
          controller: _controlador(campo),
          focusNode: _foco(campo),
          textInputAction: TextInputAction.done,
          onChanged: (texto) => _alEscribir(campo, texto),
          onSubmitted: (_) => _alEnviar(campo),
          decoration: appInputDecoration(
            hint: esDesde
                ? 'Escribe el punto de partida…'
                : 'Escribe tu destino…',
            icon: esDesde ? Icons.trip_origin : Icons.place_outlined,
          ),
        ),
        if (_sugerenciasVisibles(campo))
          // En la web, un clic fuera del campo le quita el foco antes de
          // terminar el clic. La región hace que la lista cuente como parte
          // del campo, para que la sugerencia se elija con un solo clic.
          TextFieldTapRegion(
            child: _Sugerencias(
              sugerencias: _sugerencias,
              onElegir: (lugar) => _elegirLugar(campo, lugar),
            ),
          ),
      ],
    );
  }

  List<Widget> _resultados() {
    return switch (_p.estado) {
      EstadoViaje.conResultados => [
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Líneas que te sirven',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_p.opciones.length} '
              '${_p.opciones.length == 1 ? 'opción' : 'opciones'}',
              style: AppText.small,
            ),
          ],
        ),
        for (final opcion in _p.opciones) ...[
          const SizedBox(height: 12),
          OpcionViajeCard(
            key: ValueKey('opcion-${opcion.ruta.nombre}'),
            opcion: opcion,
            elegida: identical(opcion, _p.elegida),
            onTap: () => _p.elegir(opcion),
            onIniciarViaje: _p.iniciarViaje,
          ),
        ],
      ],
      EstadoViaje.sinResultados => [
        const SizedBox(height: 24),
        if (_p.muyCerca)
          _Aviso(
            texto:
                'Todo el trayecto es caminando '
                '(${distanciaMetros(_p.origen!.posicion, _p.destino!.posicion).round()} m).',
            icono: Icons.directions_walk,
          )
        else
          const _Aviso(
            titulo: 'No encontramos una ruta directa',
            texto:
                'Puede que ese tramo no esté registrado todavía. Prueba con '
                'un destino cercano o toca un punto en el mapa.',
            icono: Icons.search_off,
          ),
      ],
      _ => const [],
    };
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLANIFICAR VIAJE', style: AppText.eyebrow),
        SizedBox(height: 6),
        Text(
          '¿A dónde vas?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

/// Ícono de la sugerencia: paradero (pasan líneas), calle, zona o lugar.
IconData _iconoDe(TipoLugar tipo) => switch (tipo) {
  TipoLugar.paradero => Icons.directions_bus_outlined,
  TipoLugar.calle => Icons.signpost_outlined,
  TipoLugar.zona => Icons.holiday_village_outlined,
  TipoLugar.lugar => Icons.place_outlined,
};

/// Lista de sugerencias, como en piuratransporta: hasta 5, primero los
/// paraderos y la base propia de Piura (al instante) y, si faltan, los del
/// buscador en línea, con su atribución.
class _Sugerencias extends StatelessWidget {
  const _Sugerencias({required this.sugerencias, required this.onElegir});

  final SugerenciasLugares sugerencias;
  final ValueChanged<Lugar> onElegir;

  @override
  Widget build(BuildContext context) {
    final s = sugerencias;
    final atribucion = s.atribucion;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, lugar) in s.todas.indexed)
            _FilaSugerencia(
              lugar: lugar,
              resaltada: s.resaltado == i,
              onTap: () => onElegir(lugar),
            ),
          if (s.buscaEnLinea && s.buscando)
            const _NotaSugerencias(
              'Buscando más lugares…',
              icono: Icons.travel_explore,
            )
          else if (s.buscaEnLinea && s.fallo)
            const _NotaSugerencias(
              'No pudimos buscar más lugares. Revisa tu conexión.',
              icono: Icons.cloud_off_outlined,
            )
          else if (s.todas.isEmpty)
            const _NotaSugerencias('No encontramos lugares con ese nombre.'),
          // Los resultados en línea llevan la atribución del servicio.
          if (s.otros.isNotEmpty && atribucion != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              child: Text(
                atribucion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaSugerencia extends StatelessWidget {
  const _FilaSugerencia({
    required this.lugar,
    required this.resaltada,
    required this.onTap,
  });

  final Lugar lugar;
  final bool resaltada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detalle = lugar.detalle;
    return Material(
      color: resaltada ? AppColors.primarySoft : Colors.transparent,
      child: InkWell(
        key: ValueKey(
          'sugerencia-${lugar.nombre}${detalle == null ? '' : ' · $detalle'}',
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                _iconoDe(lugar.tipo),
                size: 16,
                color: lugar.tipo == TipoLugar.paradero
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lugar.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    if (detalle != null)
                      Text(
                        detalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotaSugerencias extends StatelessWidget {
  const _NotaSugerencias(this.texto, {this.icono});

  final String texto;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.small,
            ),
          ),
        ],
      ),
    );
  }
}

/// Acceso de un clic a un lugar frecuente.
class _Ficha extends StatelessWidget {
  const _Ficha({super.key, required this.texto, required this.onTap});

  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Material(
        color: AppColors.field,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.icono, this.titulo});

  final String? titulo;
  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.etaBox,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null)
                  Text(
                    titulo!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                Text(texto, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titulo(),
        SizedBox(height: 32),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titulo(),
        const SizedBox(height: 24),
        const _Aviso(
          texto: 'No pudimos cargar las rutas.',
          icono: Icons.cloud_off_outlined,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onReintentar,
          style: appFilledButtonStyle(),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}

/// Guía del viaje: el pasajero avanza cada paso a mano ("Ya llegué",
/// "Ya subí", "Ya bajé"). No usa el GPS ni comparte la ubicación.
class _GuiaViaje extends StatelessWidget {
  const _GuiaViaje({required this.planificador, required this.esDemostracion});

  final PlanificadorViaje planificador;
  final bool esDemostracion;

  /// Pasos con número; "Llegaste" no cuenta.
  static const totalPasos = 4;

  @override
  Widget build(BuildContext context) {
    final o = planificador.elegida!;
    final paso = planificador.paso!;
    final destino = planificador.destino!.nombre;
    final codigo = o.ruta.codigo ?? o.ruta.nombre;
    final frecuencia = o.frecuenciaMinutos;
    final (titulo, detalle, boton, icono) = switch (paso) {
      PasoViaje.caminarAlParadero => (
        'Camina a la parada',
        '${o.sube.nombre} · ${o.metrosSubida.round()} m '
            '(${o.minutosSubida} min)',
        'Ya llegué',
        Icons.directions_walk,
      ),
      PasoViaje.esperarBus => (
        'Espera el bus $codigo',
        frecuencia == null
            ? o.ruta.nombre
            : '${o.ruta.nombre} · pasa cada ~$frecuencia min',
        'Ya subí',
        Icons.directions_bus_outlined,
      ),
      PasoViaje.aBordo => (
        'Vas a bordo',
        'Bájate cerca de ${o.baja.nombre}',
        'Ya bajé',
        Icons.event_seat_outlined,
      ),
      PasoViaje.caminarAlDestino => (
        'Camina a tu destino',
        '$destino · ${o.metrosBajada.round()} m (${o.minutosBajada} min)',
        'Ya llegué',
        Icons.directions_walk,
      ),
      PasoViaje.llegaste => (
        'Llegaste',
        destino,
        'Listo',
        Icons.check_circle_outline,
      ),
    };
    final llegaste = paso == PasoViaje.llegaste;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('EN VIAJE', style: AppText.eyebrow),
        const SizedBox(height: 6),
        Text(
          llegaste ? 'Fin del viaje' : 'Paso ${paso.index + 1} de $totalPasos',
          style: AppText.small,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: llegaste ? AppColors.greenTile : AppColors.etaBox,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icono,
                size: 26,
                color: llegaste ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: llegaste
              ? planificador.salirDelViaje
              : planificador.avanzarPaso,
          style: appFilledButtonStyle(),
          child: Text(boton),
        ),
        if (!llegaste) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: planificador.salirDelViaje,
            style: appOutlinedButtonStyle(),
            child: const Text('Salir del viaje'),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          esDemostracion
              ? 'Avanza cada paso tú mismo: tu ubicación no se comparte. Los '
                    'paraderos son propuestos: confirma en la calle dónde para '
                    'la línea.'
              : 'Avanza cada paso tú mismo: tu ubicación no se comparte.',
          style: AppText.small,
        ),
      ],
    );
  }
}
