import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/ruta.dart';
import '../../data/rutas_repository.dart';
import '../shell/app_shell.dart';
import '../shell/shell_scaffold.dart';
import 'ruta_card.dart';

/// Lista de líneas con buscador.
class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key, required this.repository});

  final RutasRepository repository;

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late Future<List<Ruta>> _rutas;
  final _busqueda = TextEditingController();
  String _consulta = '';

  @override
  void initState() {
    super.initState();
    _rutas = widget.repository.listar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _rutas = widget.repository.listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      seccion: SeccionApp.rutas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _cuerpo(horizontal: constraints.maxWidth >= 600 ? 40 : 20);
        },
      ),
    );
  }

  Widget _cuerpo({required double horizontal}) {
    return FutureBuilder<List<Ruta>>(
      future: _rutas,
      builder: (context, snapshot) {
        final terminado = snapshot.connectionState == ConnectionState.done;
        final filtradas = (snapshot.data ?? const <Ruta>[])
            .where((r) => r.coincideCon(_consulta))
            .toList();
        final total = terminado && !snapshot.hasError
            ? '${filtradas.length} ${filtradas.length == 1 ? 'línea' : 'líneas'}'
            : null;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 36, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: _Encabezado(
                  controller: _busqueda,
                  total: total,
                  onChanged: (valor) => setState(() => _consulta = valor),
                ),
              ),
            ),
            if (snapshot.hasError)
              SliverToBoxAdapter(
                child: _Mensaje(
                  titulo: 'No pudimos cargar las rutas',
                  detalle: 'Revisa tu conexión e inténtalo de nuevo.',
                  accion: FilledButton(
                    onPressed: _recargar,
                    style: appCompactButtonStyle(),
                    child: const Text('Reintentar'),
                  ),
                ),
              )
            else if (!terminado)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (filtradas.isEmpty)
              const SliverToBoxAdapter(
                child: _Mensaje(
                  titulo: 'No encontramos rutas',
                  detalle: 'Prueba con otra línea, zona o paradero.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 282,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, indice) => RutaCard(ruta: filtradas[indice]),
                    childCount: filtradas.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.controller,
    required this.onChanged,
    required this.total,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TRANSPORTE URBANO', style: AppText.eyebrow),
        const SizedBox(height: 8),
        const Text('Encuentra tu ruta', style: AppText.heading),
        const SizedBox(height: 8),
        const Text(
          'Revisa recorridos, paraderos principales y tiempos estimados antes de salir.',
          style: AppText.body,
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: appInputDecoration(
              hint: 'Buscar línea, zona o paradero',
              icon: Icons.search,
              fill: AppColors.surface,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Todas las rutas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (total != null) Text(total!, style: AppText.small),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.titulo, required this.detalle, this.accion});

  final String titulo;
  final String detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
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
