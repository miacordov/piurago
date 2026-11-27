import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/ruta.dart';
import '../../data/rutas_repository.dart';

/// El repositorio como destino de reportes, o null si no puede enviarlos
/// (datos de prueba).
FuenteReportes? fuenteReportesDe(RutasRepository repository) =>
    repository is FuenteReportes ? repository as FuenteReportes : null;

/// Abre "Reportar un cambio": el pasajero avisa que una ruta cambió o que un
/// paradero es nuevo o ya no existe. La línea puede venir elegida
/// ([idRuta]); la [ubicacion] solo se envía si el pasajero la incluye. Sin
/// [fuente] (modo demostración) avisa que no se puede enviar. Al enviar,
/// cierra y agradece con un SnackBar.
Future<void> mostrarReportarDialog(
  BuildContext context, {
  required List<Ruta> rutas,
  FuenteReportes? fuente,
  int? idRuta,
  LatLng? ubicacion,
}) async {
  final enviado = await showDialog<bool>(
    context: context,
    builder: (_) => _ReportarDialog(
      rutas: rutas,
      fuente: fuente,
      idRuta: idRuta,
      ubicacion: ubicacion,
    ),
  );
  if (enviado == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('¡Gracias! Lo revisaremos.')));
  }
}

class _ReportarDialog extends StatefulWidget {
  const _ReportarDialog({
    required this.rutas,
    required this.fuente,
    required this.idRuta,
    required this.ubicacion,
  });

  final List<Ruta> rutas;
  final FuenteReportes? fuente;
  final int? idRuta;
  final LatLng? ubicacion;

  @override
  State<_ReportarDialog> createState() => _ReportarDialogState();
}

class _ReportarDialogState extends State<_ReportarDialog> {
  static const _maximo = 500;

  final _descripcion = TextEditingController();
  TipoReporte _tipo = TipoReporte.rutaCambio;
  // Solo una línea que esté en la lista: otro valor rompe el desplegable.
  late int? _idRuta = widget.rutas.any((r) => r.idRuta == widget.idRuta)
      ? widget.idRuta
      : null;
  bool _incluirUbicacion = false;
  bool _enviando = false;
  String? _errorDescripcion;
  String? _errorEnvio;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final fuente = widget.fuente;
    if (fuente == null) return;
    final texto = _descripcion.text.trim();
    if (texto.isEmpty) {
      setState(() => _errorDescripcion = 'Describe qué cambió');
      return;
    }
    setState(() {
      _errorDescripcion = null;
      _errorEnvio = null;
      _enviando = true;
    });
    final ok = await fuente.reportar(
      NuevoReporte(
        tipo: _tipo,
        descripcion: texto,
        idRuta: _idRuta,
        ubicacion: _incluirUbicacion ? widget.ubicacion : null,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _enviando = false;
        _errorEnvio = 'No pudimos enviar el reporte. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sinConexion = widget.fuente == null;
    return AlertDialog(
      title: const Text('Reportar un cambio'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Las rutas de Piura cambian seguido. Cuéntanos qué está '
                'distinto y el equipo lo revisa.',
                style: AppText.small,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tipo in TipoReporte.values)
                    ChoiceChip(
                      label: Text(tipo.texto),
                      selected: _tipo == tipo,
                      onSelected: (_) => setState(() => _tipo = tipo),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _idRuta,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Línea (opcional)',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Ninguna en particular'),
                  ),
                  for (final ruta in widget.rutas)
                    DropdownMenuItem<int?>(
                      value: ruta.idRuta,
                      child: Text(
                        [?ruta.empresa, ruta.codigo ?? ruta.nombre].join(' · '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (valor) => setState(() => _idRuta = valor),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('reporte-descripcion'),
                controller: _descripcion,
                maxLines: 3,
                maxLength: _maximo,
                decoration: InputDecoration(
                  hintText:
                      'Ej.: Ya no entra por la Av. Grau, ahora va por '
                      'la Av. Sánchez Cerro',
                  errorText: _errorDescripcion,
                ),
              ),
              if (widget.ubicacion != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _incluirUbicacion,
                  onChanged: (valor) =>
                      setState(() => _incluirUbicacion = valor),
                  title: const Text('Incluir mi ubicación'),
                  subtitle: const Text(
                    'Sirve para ubicar el paradero. Solo se envía con este '
                    'reporte.',
                    style: AppText.small,
                  ),
                ),
              if (sinConexion)
                const Text(
                  'Sin conexión con el servidor: el reporte no se puede '
                  'enviar.',
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              if (_errorEnvio != null)
                Text(
                  _errorEnvio!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: sinConexion || _enviando ? null : _enviar,
          style: appCompactButtonStyle(),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
