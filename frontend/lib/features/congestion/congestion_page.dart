import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../shell/app_shell.dart';
import '../shell/shell_scaffold.dart';

enum FranjaCongestion { ahora, manana, tarde, noche }

class TramoCritico {
  const TramoCritico({
    required this.nombre,
    required this.zona,
    required this.demoraMinutos,
    required this.esAlta,
  });

  final String nombre;
  final String zona;
  final int demoraMinutos;
  final bool esAlta;
}

/// Pantalla del Estado del Tránsito y Congestión en Piura.
/// Representa la referencia visual 08-congestion.png y el RF-04.
class CongestionPage extends StatefulWidget {
  const CongestionPage({super.key});

  @override
  State<CongestionPage> createState() => _CongestionPageState();
}

class _CongestionPageState extends State<CongestionPage> {
  FranjaCongestion _franjaSeleccionada = FranjaCongestion.ahora;

  static const List<TramoCritico> _tramos = [
    TramoCritico(
      nombre: 'Óvalo Bolognesi ↔ Av. Sánchez Cerro',
      zona: 'Centro de Piura',
      demoraMinutos: 14,
      esAlta: true,
    ),
    TramoCritico(
      nombre: 'Mercado Modelo ↔ Jr. Gonzalo Farfán',
      zona: 'Comercio central',
      demoraMinutos: 12,
      esAlta: true,
    ),
    TramoCritico(
      nombre: 'Av. Andrés Avelino Cáceres ↔ Puente Sánchez Cerro',
      zona: 'Cruce Piura - Castilla',
      demoraMinutos: 8,
      esAlta: false,
    ),
    TramoCritico(
      nombre: 'Av. Grau ↔ Av. Vice',
      zona: 'Zona Bancaria',
      demoraMinutos: 7,
      esAlta: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      seccion: SeccionApp.congestion,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final esCelular = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: esCelular ? 16 : 36,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESTADO DEL TRÁNSITO', style: AppText.eyebrow),
                const SizedBox(height: 8),
                const Text('Congestión en Piura', style: AppText.heading),
                const SizedBox(height: 8),
                const Text(
                  'Histórico de horas pico y reporte de tramos con mayor tráfico vehicular.',
                  style: AppText.body,
                ),
                const SizedBox(height: 24),
                _SelectorPestanas(
                  seleccionada: _franjaSeleccionada,
                  onSelect: (f) => setState(() => _franjaSeleccionada = f),
                ),
                const SizedBox(height: 24),
                _TarjetaNivelGeneral(franja: _franjaSeleccionada),
                const SizedBox(height: 24),
                _TarjetasMetricas(esCelular: esCelular, franja: _franjaSeleccionada),
                const SizedBox(height: 32),
                const Text(
                  'TRAMOS CRÍTICOS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 14),
                for (final tramo in _tramos)
                  _FilaTramoCritico(tramo: tramo, esCelular: esCelular),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectorPestanas extends StatelessWidget {
  const _SelectorPestanas({
    required this.seleccionada,
    required this.onSelect,
  });

  final FranjaCongestion seleccionada;
  final ValueChanged<FranjaCongestion> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _BotonPestana(
            titulo: 'Ahora',
            activa: seleccionada == FranjaCongestion.ahora,
            onTap: () => onSelect(FranjaCongestion.ahora),
          ),
          _BotonPestana(
            titulo: 'Mañana',
            subtitulo: '6:00 - 11:59',
            activa: seleccionada == FranjaCongestion.manana,
            onTap: () => onSelect(FranjaCongestion.manana),
          ),
          _BotonPestana(
            titulo: 'Tarde',
            subtitulo: '12:00 - 17:59',
            activa: seleccionada == FranjaCongestion.tarde,
            onTap: () => onSelect(FranjaCongestion.tarde),
          ),
          _BotonPestana(
            titulo: 'Noche',
            subtitulo: '18:00 - 22:00',
            activa: seleccionada == FranjaCongestion.noche,
            onTap: () => onSelect(FranjaCongestion.noche),
          ),
        ],
      ),
    );
  }
}

class _BotonPestana extends StatelessWidget {
  const _BotonPestana({
    required this.titulo,
    this.subtitulo,
    required this.activa,
    required this.onTap,
  });

  final String titulo;
  final String? subtitulo;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activa ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: activa ? 1 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
                  color: activa ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(width: 6),
                Text(
                  subtitulo!,
                  style: TextStyle(
                    fontSize: 11,
                    color: activa ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaNivelGeneral extends StatelessWidget {
  const _TarjetaNivelGeneral({required this.franja});

  final FranjaCongestion franja;

  @override
  Widget build(BuildContext context) {
    // Datos de barras por hora de 6h a 20h
    final horas = List.generate(15, (i) => 6 + i);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'Nivel general en Piura',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: AppColors.danger),
                    SizedBox(width: 6),
                    Text(
                      'Tránsito lento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gráfico de barras por hora
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in horas)
                  Expanded(
                    child: _BarraHora(hora: h, franja: franja),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraHora extends StatelessWidget {
  const _BarraHora({required this.hora, required this.franja});

  final int hora;
  final FranjaCongestion franja;

  @override
  Widget build(BuildContext context) {
    // Picos en Piura: 7h-9h (mañana), 12h-14h (mediodía/almuerzo), 18h-20h (tarde/noche)
    double alturaPorcentaje;
    Color color;

    if (hora == 7 || hora == 8 || hora == 13 || hora == 18 || hora == 19) {
      alturaPorcentaje = 0.85;
      color = AppColors.danger;
    } else if (hora == 9 || hora == 12 || hora == 14 || hora == 17 || hora == 20) {
      alturaPorcentaje = 0.55;
      color = AppColors.primary;
    } else {
      alturaPorcentaje = 0.28;
      color = AppColors.success;
    }

    return Tooltip(
      message: '$hora:00 hrs · Nivel ${(alturaPorcentaje * 100).round()}%',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 75 * alturaPorcentaje,
            width: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$hora',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetasMetricas extends StatelessWidget {
  const _TarjetasMetricas({required this.esCelular, required this.franja});

  final bool esCelular;
  final FranjaCongestion franja;

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      const _MetricaCard(
        icono: Icons.timer_outlined,
        titulo: 'Demora promedio',
        valor: '+14 min',
        detalle: 'Sobre el tiempo base',
        colorIcono: AppColors.primary,
      ),
      const _MetricaCard(
        icono: Icons.speed_outlined,
        titulo: 'Velocidad promedio',
        valor: '16.2 km/h',
        detalle: 'Combis en zona urbana',
        colorIcono: AppColors.warning,
      ),
      const _MetricaCard(
        icono: Icons.warning_amber_rounded,
        titulo: 'Puntos críticos',
        valor: '4 zonas',
        detalle: 'Con detención mayor a 5 min',
        colorIcono: AppColors.danger,
      ),
    ];

    if (esCelular) {
      return Column(
        children: [
          for (final t in tarjetas) ...[
            t,
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < tarjetas.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: tarjetas[i]),
        ],
      ],
    );
  }
}

class _MetricaCard extends StatelessWidget {
  const _MetricaCard({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.colorIcono,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final String detalle;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: colorIcono),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(detalle, style: AppText.small),
        ],
      ),
    );
  }
}

class _FilaTramoCritico extends StatelessWidget {
  const _FilaTramoCritico({
    required this.tramo,
    required this.esCelular,
  });

  final TramoCritico tramo;
  final bool esCelular;

  @override
  Widget build(BuildContext context) {
    if (esCelular) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tramo.esAlta ? AppColors.dangerSoft : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.traffic,
                    size: 20,
                    color: tramo.esAlta ? AppColors.danger : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tramo.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(tramo.zona, style: AppText.small),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '+${tramo.demoraMinutos} min',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tramo.esAlta ? AppColors.danger : AppColors.warning,
                      ),
                    ),
                    Text(
                      tramo.esAlta ? 'Congestión Alta' : 'Congestión Media',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.mapa),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Ver mapa'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tramo.esAlta ? AppColors.dangerSoft : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.traffic,
              size: 20,
              color: tramo.esAlta ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tramo.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(tramo.zona, style: AppText.small),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${tramo.demoraMinutos} min',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tramo.esAlta ? AppColors.danger : AppColors.warning,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tramo.esAlta ? 'Congestión Alta' : 'Congestión Media',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.mapa),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Ver mapa'),
          ),
        ],
      ),
    );
  }
}
