import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../data/lugares/buscador_lugares.dart';
import '../../data/models/lugar.dart';
import '../../data/models/paradero.dart';
import '../../data/models/ruta.dart';
import '../../data/rutas_repository.dart';
import '../shell/app_shell.dart';
import '../shell/shell_scaffold.dart';
import '../viaje/mapa_viaje.dart';
import '../viaje/planificador_viaje.dart';
import '../viaje/planificar_panel.dart';
import 'ruta_map.dart';
import 'ruta_panel.dart';

/// Pantalla del mapa, con dos modos de panel:
/// - Planificar viaje ("¿A dónde vas?"), si no se indica una ruta (por
///   ejemplo, al entrar desde "Mapa" en la barra lateral).
/// - Ruta seleccionada, al llegar desde "Ver en mapa". Su panel tiene un
///   botón para pasar a Planificar viaje sin cambiar de pantalla.
class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.repository,
    this.buscadorLugares,
    this.lugaresConocidos = const [],
    this.idRuta,
    this.mostrarMapa = true,
  });

  final RutasRepository repository;

  /// Buscador de lugares en línea de Planificar viaje (opcional).
  final BuscadorLugares? buscadorLugares;

  /// Base propia de calles y lugares de Piura para las sugerencias.
  final List<Lugar> lugaresConocidos;
  final int? idRuta;

  /// Permite reemplazar el mapa real por un recuadro vacío (para las pruebas,
  /// que no tienen acceso a internet).
  final bool mostrarMapa;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _DatosMapa {
  const _DatosMapa(this.ruta, this.paraderos);

  final Ruta? ruta;
  final List<Paradero> paraderos;
}

class _MapPageState extends State<MapPage> {
  late Future<_DatosMapa> _datos;
  PlanificadorViaje? _planificador;

  @override
  void initState() {
    super.initState();
    if (widget.idRuta == null) {
      _iniciarPlanificador();
    } else {
      _datos = _cargar();
    }
  }

  @override
  void dispose() {
    _planificador?.dispose();
    super.dispose();
  }

  void _iniciarPlanificador() {
    _planificador = PlanificadorViaje(
      widget.repository,
      lugaresConocidos: widget.lugaresConocidos,
    )..cargar();
  }

  void _planificarViaje() {
    setState(_iniciarPlanificador);
  }

  Future<_DatosMapa> _cargar() async {
    final rutas = await widget.repository.listar();
    if (rutas.isEmpty) return const _DatosMapa(null, []);
    final ruta = rutas.firstWhere(
      (r) => r.idRuta == widget.idRuta,
      orElse: () => rutas.first,
    );
    final paraderos = await widget.repository.paraderos(ruta.idRuta);
    return _DatosMapa(ruta, paraderos);
  }

  void _recargar() {
    setState(() {
      _datos = _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final planificador = _planificador;
    if (planificador != null) {
      return ShellScaffold(
        seccion: SeccionApp.mapa,
        child: _Disposicion(
          mapa: widget.mostrarMapa
              ? MapaViaje(
                  planificador: planificador,
                  esDemostracion: widget.repository.esDemostracion,
                )
              : const ColoredBox(color: AppColors.field),
          panel: PlanificarPanel(
            planificador: planificador,
            buscadorLugares: widget.buscadorLugares,
            esDemostracion: widget.repository.esDemostracion,
          ),
          panelEnHoja: (controlador) => PlanificarPanel(
            planificador: planificador,
            buscadorLugares: widget.buscadorLugares,
            esDemostracion: widget.repository.esDemostracion,
            controladorScroll: controlador,
          ),
        ),
      );
    }
    return ShellScaffold(
      seccion: SeccionApp.mapa,
      child: FutureBuilder<_DatosMapa>(
        future: _datos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Aviso(
              titulo: 'No pudimos cargar el mapa',
              detalle: 'Revisa tu conexión e inténtalo de nuevo.',
              accion: FilledButton(
                onPressed: _recargar,
                style: appCompactButtonStyle(),
                child: const Text('Reintentar'),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final ruta = snapshot.data?.ruta;
          if (ruta == null) {
            return const _Aviso(
              titulo: 'Todavía no hay rutas',
              detalle: 'Cuando se carguen, podrás verlas en el mapa.',
            );
          }
          return _Contenido(
            ruta: ruta,
            paraderos: snapshot.data!.paraderos,
            esDemostracion: widget.repository.esDemostracion,
            mostrarMapa: widget.mostrarMapa,
            onPlanificarViaje: _planificarViaje,
          );
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.ruta,
    required this.paraderos,
    required this.esDemostracion,
    required this.mostrarMapa,
    required this.onPlanificarViaje,
  });

  final Ruta ruta;
  final List<Paradero> paraderos;
  final bool esDemostracion;
  final bool mostrarMapa;
  final VoidCallback onPlanificarViaje;

  @override
  Widget build(BuildContext context) {
    final Widget mapa = mostrarMapa
        ? RutaMap(
            key: ValueKey(ruta.idRuta),
            paraderos: paraderos,
            esDemostracion: esDemostracion,
          )
        : const ColoredBox(color: AppColors.field);
    final panel = RutaPanel(
      ruta: ruta,
      paraderos: paraderos,
      onPlanificarViaje: onPlanificarViaje,
    );
    return _Disposicion(mapa: mapa, panel: panel);
  }
}

/// Mapa y panel: en pantallas de 700 px o más, el panel de 359 px va a la
/// derecha; en las angostas, el mapa arriba (hasta 420 px) y el panel debajo.
class _Disposicion extends StatelessWidget {
  const _Disposicion({
    required this.mapa,
    required this.panel,
    this.panelEnHoja,
  });

  final Widget mapa;
  final Widget panel;

  /// Si se indica, en pantallas angostas el mapa ocupa todo y el panel es
  /// una hoja que se desliza desde abajo (como en Moovit y piuratransporta).
  final Widget Function(ScrollController controlador)? panelEnHoja;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final enHoja = panelEnHoja;
        if (constraints.maxWidth < 700 && enHoja != null) {
          return Stack(
            children: [
              Positioned.fill(child: mapa),
              DraggableScrollableSheet(
                initialChildSize: 0.55,
                minChildSize: 0.2,
                maxChildSize: 0.95,
                snap: true,
                snapSizes: const [0.55],
                builder: (context, controlador) => Material(
                  color: AppColors.surface,
                  elevation: 8,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      enHoja(controlador),
                      // Asa para arrastrar la hoja.
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.track,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        if (constraints.maxWidth >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mapa),
              Container(
                width: 359,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                child: panel,
              ),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(
              height: math.min(420, constraints.maxHeight * 0.5),
              child: mapa,
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: panel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.titulo, required this.detalle, this.accion});

  final String titulo;
  final String detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(detalle, textAlign: TextAlign.center, style: AppText.body),
            if (accion != null) ...[const SizedBox(height: 16), accion!],
          ],
        ),
      ),
    );
  }
}
