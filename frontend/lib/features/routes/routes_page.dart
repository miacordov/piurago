import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/ruta.dart';
import '../../data/rutas_repository.dart';
import '../shell/app_shell.dart';
import '../shell/shell_scaffold.dart';
import 'filtro_rutas.dart';
import 'ruta_card.dart';

/// Lista de líneas, como la de Moovit y la de piuratransporta.com: buscador
/// (sin tildes, por código, zona, empresa o lugar), filtros por tipo de
/// servicio y una fila compacta por línea. Arriba, un acceso a Planificar
/// viaje para quien no sabe qué línea tomar.
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
  TipoServicio? _tipo;

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

  void _limpiar() {
    _busqueda.clear();
    setState(() {
      _consulta = '';
      _tipo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      seccion: SeccionApp.rutas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _cuerpo(horizontal: constraints.maxWidth >= 600 ? 40 : 16);
        },
      ),
    );
  }

  Widget _cuerpo({required double horizontal}) {
    return FutureBuilder<List<Ruta>>(
      future: _rutas,
      builder: (context, snapshot) {
        final terminado = snapshot.connectionState == ConnectionState.done;
        final todas = snapshot.data ?? const <Ruta>[];
        // Los números de los filtros cuentan lo que coincide con la búsqueda.
        final porTexto = filtrarRutas(todas, consulta: _consulta);
        final cuenta = contarPorTipo([for (final r in porTexto) r.ruta]);
        final filtradas = _tipo == null
            ? porTexto
            : [
                for (final r in porTexto)
                  if (TipoServicio.de(r.ruta) == _tipo) r,
              ];
        final total = terminado && !snapshot.hasError
            ? '${filtradas.length} ${filtradas.length == 1 ? 'línea' : 'líneas'}'
            : null;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: _Encabezado(
                    controller: _busqueda,
                    total: total,
                    cuenta: terminado && !snapshot.hasError ? cuenta : null,
                    tipo: _tipo,
                    onChanged: (valor) => setState(() => _consulta = valor),
                    onBorrar: _limpiar,
                    onTipo: (tipo) => setState(() => _tipo = tipo),
                  ),
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
              SliverToBoxAdapter(
                child: _Mensaje(
                  titulo: 'No encontramos rutas',
                  detalle: 'Prueba con otra línea, calle o lugar.',
                  accion: OutlinedButton(
                    onPressed: _limpiar,
                    child: const Text('Limpiar búsqueda'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 40),
                sliver: SliverConstrainedCrossAxis(
                  maxExtent: 880,
                  sliver: SliverList.separated(
                    itemCount: filtradas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, indice) {
                      final r = filtradas[indice];
                      return RutaCard(
                        key: ValueKey('ruta-${r.ruta.idRuta}'),
                        ruta: r.ruta,
                        lugarCoincidente: r.lugarCoincidente,
                      );
                    },
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
    required this.onBorrar,
    required this.onTipo,
    required this.total,
    required this.cuenta,
    required this.tipo,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onBorrar;
  final ValueChanged<TipoServicio?> onTipo;
  final String? total;
  final Map<TipoServicio?, int>? cuenta;
  final TipoServicio? tipo;

  @override
  Widget build(BuildContext context) {
    final cuenta = this.cuenta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TRANSPORTE URBANO', style: AppText.eyebrow),
        const SizedBox(height: 6),
        const Text('Encuentra tu ruta', style: AppText.heading),
        const SizedBox(height: 16),
        const _AccesoPlanificar(),
        const SizedBox(height: 16),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, valor, _) => TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration:
                appInputDecoration(
                  hint: 'Busca una línea, calle o lugar',
                  icon: Icons.search,
                  fill: AppColors.surface,
                ).copyWith(
                  suffixIcon: valor.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar búsqueda',
                          onPressed: onBorrar,
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
          ),
        ),
        if (cuenta != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FiltroTipo(
                texto: 'Todas (${cuenta[null]})',
                elegido: tipo == null,
                onTap: () => onTipo(null),
              ),
              for (final t in TipoServicio.values)
                _FiltroTipo(
                  texto: '${t.plural} (${cuenta[t]})',
                  elegido: tipo == t,
                  onTap: () => onTipo(t),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (total != null) Text(total!, style: AppText.small),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Acceso a Planificar viaje, para quien no sabe qué línea tomar.
class _AccesoPlanificar extends StatelessWidget {
  const _AccesoPlanificar();

  @override
  Widget build(BuildContext context) {
    final boton = FilledButton.icon(
      onPressed: () =>
          Navigator.of(context).pushReplacementNamed(AppRoutes.mapa),
      style: appCompactButtonStyle(),
      icon: const Icon(Icons.alt_route, size: 16),
      label: const Text('Planificar viaje'),
    );
    const textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿No sabes qué línea tomar?', style: AppText.label),
        SizedBox(height: 2),
        Text(
          'Dinos a dónde vas y te decimos qué línea te sirve.',
          style: AppText.small,
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [textos, const SizedBox(height: 10), boton],
            );
          }
          return Row(
            children: [
              const Icon(Icons.alt_route, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(child: textos),
              const SizedBox(width: 12),
              boton,
            ],
          );
        },
      ),
    );
  }
}

class _FiltroTipo extends StatelessWidget {
  const _FiltroTipo({
    required this.texto,
    required this.elegido,
    required this.onTap,
  });

  final String texto;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(texto),
      selected: elegido,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: elegido ? FontWeight.w600 : FontWeight.w400,
        color: elegido ? AppColors.primary : AppColors.text,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primarySoft,
      side: BorderSide(color: elegido ? AppColors.primary : AppColors.border),
      shape: const StadiumBorder(),
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
