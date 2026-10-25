import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/paradero.dart';
import '../../data/models/ruta.dart';
import '../../data/rutas_repository.dart';
import '../shell/app_shell.dart';
import '../shell/shell_scaffold.dart';
import 'ruta_map.dart';
import 'ruta_panel.dart';

/// Pantalla del mapa: muestra la ruta elegida sobre OpenStreetMap y su panel.
/// Si no se indica una ruta, abre la primera de la lista.
class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.repository,
    this.idRuta,
    this.mostrarMapa = true,
  });

  final RutasRepository repository;
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

  @override
  void initState() {
    super.initState();
    _datos = _cargar();
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
  });

  final Ruta ruta;
  final List<Paradero> paraderos;
  final bool esDemostracion;
  final bool mostrarMapa;

  @override
  Widget build(BuildContext context) {
    final Widget mapa = mostrarMapa
        ? RutaMap(
            key: ValueKey(ruta.idRuta),
            paraderos: paraderos,
            esDemostracion: esDemostracion,
          )
        : const ColoredBox(color: AppColors.field);
    final panel = RutaPanel(ruta: ruta, paraderos: paraderos);

    return LayoutBuilder(
      builder: (context, constraints) {
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
