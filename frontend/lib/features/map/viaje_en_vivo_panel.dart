import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/paradero.dart';
import '../../data/models/ruta.dart';

/// Panel lateral cuando el usuario está en viaje en vivo (referencia 06-viaje-en-vivo.png).
/// Muestra el avance colaborativo por paraderos y el botón para finalizar viaje.
class ViajeEnVivoPanel extends StatefulWidget {
  const ViajeEnVivoPanel({
    super.key,
    required this.ruta,
    required this.paraderos,
    required this.onFinalizarViaje,
    this.onParaderoAlcanzado,
  });

  final Ruta ruta;
  final List<Paradero> paraderos;
  final VoidCallback onFinalizarViaje;
  final void Function(Paradero paraderoActual)? onParaderoAlcanzado;

  @override
  State<ViajeEnVivoPanel> createState() => _ViajeEnVivoPanelState();
}

class _ViajeEnVivoPanelState extends State<ViajeEnVivoPanel> {
  int _indiceParaderoActual = 0;
  int _segundosRestantes = 95;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarCuentaRegresiva();
    if (widget.paraderos.isNotEmpty) {
      widget.onParaderoAlcanzado?.call(widget.paraderos.first);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarCuentaRegresiva() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_segundosRestantes > 0) {
          _segundosRestantes--;
        } else {
          // Avanza simuladamente al siguiente paradero al llegar a 0
          if (_indiceParaderoActual < widget.paraderos.length - 1) {
            _indiceParaderoActual++;
            _segundosRestantes = 120;
            widget.onParaderoAlcanzado
                ?.call(widget.paraderos[_indiceParaderoActual]);
          }
        }
      });
    });
  }

  void _avanzarParaderoManual() {
    if (_indiceParaderoActual < widget.paraderos.length - 1) {
      setState(() {
        _indiceParaderoActual++;
        _segundosRestantes = 110;
      });
      widget.onParaderoAlcanzado?.call(widget.paraderos[_indiceParaderoActual]);
    }
  }

  String _formatearTiempo(int seg) {
    final m = (seg ~/ 60).toString().padLeft(2, '0');
    final s = (seg % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final paraderos = widget.paraderos;
    final tieneParaderos = paraderos.isNotEmpty;
    final paraderoActual = tieneParaderos ? paraderos[_indiceParaderoActual] : null;
    final siguienteParadero =
        (tieneParaderos && _indiceParaderoActual < paraderos.length - 1)
            ? paraderos[_indiceParaderoActual + 1]
            : null;

    final progreso = 1.0 - (_segundosRestantes / 120.0).clamp(0.0, 1.0);

    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('EN VIAJE', style: AppText.eyebrow),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: AppColors.danger),
                      SizedBox(width: 6),
                      Text(
                        'EN VIVO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.ruta.codigo} · ${widget.ruta.nombre}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Compartiendo tu ubicación como colaborador',
              style: AppText.small,
            ),
            const SizedBox(height: 20),
            // Tarjeta de Paradero Actual y Siguiente
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.etaBox,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.near_me, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          paraderoActual != null
                              ? 'Cerca de: ${paraderoActual.nombre}'
                              : 'En ruta',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    siguienteParadero != null
                        ? 'Siguiente: ${siguienteParadero.nombre}'
                        : 'Llegando al destino final',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Tiempo al próximo paradero:',
                          style: AppText.small,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatearTiempo(_segundosRestantes),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 6,
                      backgroundColor: AppColors.track,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text(
                  'PARADEROS DEL RECORRIDO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textMuted,
                  ),
                ),
                if (_indiceParaderoActual < paraderos.length - 1)
                  TextButton.icon(
                    onPressed: _avanzarParaderoManual,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.skip_next, size: 16),
                    label: const Text('Simular avance', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < paraderos.length; i++)
              _FilaParaderoEnVivo(
                indice: i,
                paradero: paraderos[i],
                esActual: i == _indiceParaderoActual,
                yaPaso: i < _indiceParaderoActual,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onFinalizarViaje,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dangerStrong,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Finalizar viaje'),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Tu ubicación se comparte de forma anónima.',
                style: AppText.small,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaParaderoEnVivo extends StatelessWidget {
  const _FilaParaderoEnVivo({
    required this.indice,
    required this.paradero,
    required this.esActual,
    required this.yaPaso,
  });

  final int indice;
  final Paradero paradero;
  final bool esActual;
  final bool yaPaso;

  @override
  Widget build(BuildContext context) {
    Color colorPunto;
    Widget indicador;

    if (esActual) {
      colorPunto = AppColors.success;
      indicador = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.greenTile,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 3, backgroundColor: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Estás aquí',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    } else if (yaPaso) {
      colorPunto = AppColors.border;
      indicador = const Icon(Icons.check, size: 14, color: AppColors.textMuted);
    } else {
      colorPunto = AppColors.primary;
      indicador = Text(
        '+${((indice) * 3)} min',
        style: AppText.small,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: esActual ? AppColors.greenTile : Colors.transparent,
              border: Border.all(color: colorPunto, width: esActual ? 2 : 1),
            ),
            child: Text(
              '${indice + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: esActual ? FontWeight.w700 : FontWeight.w500,
                color: esActual ? AppColors.success : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              paradero.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: esActual ? FontWeight.w700 : FontWeight.w400,
                color: yaPaso
                    ? AppColors.textMuted
                    : (esActual ? AppColors.text : AppColors.text),
              ),
            ),
          ),
          const SizedBox(width: 8),
          indicador,
        ],
      ),
    );
  }
}
