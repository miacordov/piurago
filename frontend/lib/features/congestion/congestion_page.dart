import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/resumen_congestion.dart';
import '../../data/rutas_repository.dart';
import '../shell/app_shell.dart';
import '../shell/shell_scaffold.dart';

/// Franja horaria del histórico del backend (FranjaHoraria.java).
class _Franja {
  const _Franja(this.clave, this.titulo, this.horas);

  final String clave;
  final String titulo;
  final String horas;
}

const _franjas = [
  _Franja('MANANA_PICO', 'Mañana', '6:00 - 9:59'),
  _Franja('MEDIO_DIA', 'Mediodía', '10:00 - 16:59'),
  _Franja('TARDE_PICO', 'Tarde', '17:00 - 20:59'),
  _Franja('NOCHE', 'Noche', '21:00 - 5:59'),
];

String _tituloFranja(String clave) => _franjas
    .firstWhere(
      (f) => f.clave == clave,
      orElse: () => _Franja(clave, clave, ''),
    )
    .titulo;

const _dias = {
  'LUN': 'lunes',
  'MAR': 'martes',
  'MIE': 'miércoles',
  'JUE': 'jueves',
  'VIE': 'viernes',
  'SAB': 'sábado',
  'DOM': 'domingo',
};

String _etiquetaNivel(NivelCongestion? nivel) => switch (nivel) {
  NivelCongestion.alta => 'Tránsito lento',
  NivelCongestion.media => 'Tránsito moderado',
  NivelCongestion.baja => 'Tránsito fluido',
  null => 'Sin datos',
};

Color _colorNivel(NivelCongestion? nivel) => switch (nivel) {
  NivelCongestion.alta => AppColors.danger,
  NivelCongestion.media => AppColors.warning,
  NivelCongestion.baja => AppColors.success,
  null => AppColors.textMuted,
};

Color _fondoNivel(NivelCongestion? nivel) => switch (nivel) {
  NivelCongestion.alta => AppColors.dangerSoft,
  NivelCongestion.media => AppColors.orangeTile,
  NivelCongestion.baja => AppColors.greenTile,
  null => AppColors.field,
};

/// Pantalla del Estado del Tránsito y Congestión en Piura.
/// Representa la referencia visual 08-congestion.png y el RF-04.
///
/// Los datos salen del histórico del backend, que se arma con los viajes que
/// comparten los pasajeros y se recalcula cada hora. Con los datos de prueba
/// (sin backend) la pantalla lo avisa en vez de mostrar cifras inventadas.
class CongestionPage extends StatefulWidget {
  const CongestionPage({super.key, this.repository});

  /// Si implementa [FuenteCongestion] (el repositorio del backend), de ahí
  /// sale el resumen; también se usa para abrir en el mapa la ruta de un
  /// tramo.
  final RutasRepository? repository;

  @override
  State<CongestionPage> createState() => _CongestionPageState();
}

class _CongestionPageState extends State<CongestionPage> {
  /// Null: "Ahora" (el backend usa la franja y el día actuales).
  String? _franjaSeleccionada;
  Future<ResumenCongestion?>? _carga;

  FuenteCongestion? get _fuente {
    final repo = widget.repository;
    return repo is FuenteCongestion ? repo as FuenteCongestion : null;
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _carga = _fuente?.resumenCongestion(franjaHoraria: _franjaSeleccionada);
  }

  void _seleccionar(String? franja) {
    if (franja == _franjaSeleccionada) return;
    setState(() {
      _franjaSeleccionada = franja;
      _cargar();
    });
  }

  Future<void> _verMapa(TramoCritico tramo) async {
    final repo = widget.repository;
    int? idRuta;
    if (repo != null && tramo.codigoRuta != null) {
      for (final r in await repo.listar()) {
        if (r.codigo == tramo.codigoRuta) {
          idRuta = r.idRuta;
          break;
        }
      }
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(AppRoutes.mapa, arguments: idRuta);
  }

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
                  'Cómo está el tránsito según los viajes que comparten los pasajeros. Se actualiza cada hora.',
                  style: AppText.body,
                ),
                const SizedBox(height: 24),
                _SelectorPestanas(
                  seleccionada: _franjaSeleccionada,
                  onSelect: _seleccionar,
                ),
                const SizedBox(height: 24),
                if (_fuente == null)
                  const _Aviso(
                    icono: Icons.cloud_off_outlined,
                    texto:
                        'La congestión se muestra cuando la app está conectada al servidor. '
                        'En el modo de demostración no hay viajes compartidos.',
                  )
                else
                  FutureBuilder<ResumenCongestion?>(
                    future: _carga,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final resumen = snapshot.data;
                      if (resumen == null) {
                        return _Aviso(
                          icono: Icons.wifi_off_rounded,
                          texto: 'No pudimos cargar la congestión. Revisa tu conexión e inténtalo de nuevo.',
                          accion: OutlinedButton(
                            onPressed: () => setState(_cargar),
                            child: const Text('Reintentar'),
                          ),
                        );
                      }
                      return _Contenido(
                        resumen: resumen,
                        esCelular: esCelular,
                        onVerMapa: _verMapa,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.resumen,
    required this.esCelular,
    required this.onVerMapa,
  });

  final ResumenCongestion resumen;
  final bool esCelular;
  final ValueChanged<TramoCritico> onVerMapa;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TarjetaNivelGeneral(resumen: resumen),
        if (!resumen.tieneDatos) ...[
          const SizedBox(height: 16),
          const _Aviso(
            icono: Icons.info_outline,
            texto:
                'Todavía no hay viajes compartidos en esta franja. Cuando los pasajeros '
                'compartan su ubicación durante el viaje, aquí verás cómo está el tránsito.',
          ),
        ],
        const SizedBox(height: 24),
        _TarjetasMetricas(esCelular: esCelular, resumen: resumen),
        if (resumen.tieneDatos) ...[
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
          if (resumen.tramosCriticos.isEmpty)
            const Text(
              'No hay tramos lentos en esta franja.',
              style: AppText.body,
            )
          else
            for (final tramo in resumen.tramosCriticos)
              _FilaTramoCritico(
                tramo: tramo,
                esCelular: esCelular,
                onVerMapa: () => onVerMapa(tramo),
              ),
        ],
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto, this.accion});

  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto, style: AppText.body),
                if (accion != null) ...[const SizedBox(height: 12), accion!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorPestanas extends StatelessWidget {
  const _SelectorPestanas({required this.seleccionada, required this.onSelect});

  final String? seleccionada;
  final ValueChanged<String?> onSelect;

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
            key: const Key('pestana-AHORA'),
            titulo: 'Ahora',
            activa: seleccionada == null,
            onTap: () => onSelect(null),
          ),
          for (final f in _franjas)
            _BotonPestana(
              key: Key('pestana-${f.clave}'),
              titulo: f.titulo,
              subtitulo: f.horas,
              activa: seleccionada == f.clave,
              onTap: () => onSelect(f.clave),
            ),
        ],
      ),
    );
  }
}

class _BotonPestana extends StatelessWidget {
  const _BotonPestana({
    super.key,
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
  const _TarjetaNivelGeneral({required this.resumen});

  final ResumenCongestion resumen;

  @override
  Widget build(BuildContext context) {
    final nivel = resumen.nivelGeneral;
    final porClave = {for (final f in resumen.porFranja) f.franjaHoraria: f};
    final dia = _dias[resumen.diaSemana] ?? resumen.diaSemana;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nivel general en Piura',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Los $dia · ${_tituloFranja(resumen.franjaHoraria)}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _fondoNivel(nivel),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: _colorNivel(nivel),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _etiquetaNivel(nivel),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _colorNivel(nivel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Una barra por franja del mismo día.
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final f in _franjas)
                  Expanded(
                    child: _BarraFranja(
                      franja: f,
                      datos: porClave[f.clave],
                      actual: f.clave == resumen.franjaHoraria,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraFranja extends StatelessWidget {
  const _BarraFranja({
    required this.franja,
    required this.datos,
    required this.actual,
  });

  final _Franja franja;
  final FranjaCongestionResumen? datos;
  final bool actual;

  @override
  Widget build(BuildContext context) {
    final nivel = datos?.nivel;
    final velocidad = datos?.velocidadPromedio;

    final alturaPorcentaje = switch (nivel) {
      NivelCongestion.alta => 0.9,
      NivelCongestion.media => 0.6,
      NivelCongestion.baja => 0.3,
      null => 0.08,
    };

    return Tooltip(
      key: Key('barra-${franja.clave}'),
      message: nivel == null
          ? '${franja.titulo} · sin datos todavía'
          : '${franja.titulo} · ${_etiquetaNivel(nivel)}'
                '${velocidad == null ? '' : ' · ${velocidad.toStringAsFixed(1)} km/h'}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            velocidad == null ? '' : '${velocidad.round()} km/h',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Container(
            height: 90 * alturaPorcentaje,
            width: 36,
            decoration: BoxDecoration(
              color: nivel == null ? AppColors.track : _colorNivel(nivel),
              borderRadius: BorderRadius.circular(4),
              border: actual
                  ? Border.all(color: AppColors.text, width: 2)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            franja.titulo,
            style: TextStyle(
              fontSize: 11,
              color: actual ? AppColors.text : AppColors.textMuted,
              fontWeight: actual ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetasMetricas extends StatelessWidget {
  const _TarjetasMetricas({required this.esCelular, required this.resumen});

  final bool esCelular;
  final ResumenCongestion resumen;

  @override
  Widget build(BuildContext context) {
    final demora = resumen.demoraPromedio;
    final velocidad = resumen.velocidadPromedio;
    final rutas = resumen.rutasConDatos;
    final hayDatos = resumen.tieneDatos;

    final tarjetas = [
      _MetricaCard(
        icono: Icons.timer_outlined,
        titulo: 'Demora promedio',
        valor: hayDatos && demora != null
            ? '+${demora.toStringAsFixed(1)} min/km'
            : '—',
        detalle: 'Frente a ir sin tráfico (25 km/h)',
        colorIcono: AppColors.primary,
      ),
      _MetricaCard(
        icono: Icons.speed_outlined,
        titulo: 'Velocidad promedio',
        valor: hayDatos && velocidad != null
            ? '${velocidad.toStringAsFixed(1)} km/h'
            : '—',
        detalle: hayDatos
            ? 'Promedio de $rutas ${rutas == 1 ? 'ruta' : 'rutas'} con datos'
            : 'Combis con pasajeros compartiendo su viaje',
        colorIcono: AppColors.warning,
      ),
      _MetricaCard(
        icono: Icons.warning_amber_rounded,
        titulo: 'Puntos críticos',
        valor: hayDatos ? '${resumen.puntosCriticos}' : '—',
        detalle: 'Tramos recorridos a menos de 10 km/h',
        colorIcono: AppColors.danger,
      ),
    ];

    if (esCelular) {
      return Column(
        children: [
          for (final t in tarjetas) ...[t, const SizedBox(height: 12)],
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
    required this.onVerMapa,
  });

  final TramoCritico tramo;
  final bool esCelular;
  final VoidCallback onVerMapa;

  @override
  Widget build(BuildContext context) {
    final esAlta = tramo.nivel == NivelCongestion.alta;
    final nombre = tramo.hasta == null
        ? tramo.desde
        : '${tramo.desde} → ${tramo.hasta}';
    final linea = tramo.codigoRuta != null
        ? 'Línea ${tramo.codigoRuta}'
        : (tramo.nombreRuta ?? 'Ruta');
    final zona = '$linea · a ${tramo.velocidadPromedio.round()} km/h';

    final icono = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: esAlta ? AppColors.dangerSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.traffic,
        size: 20,
        color: esAlta ? AppColors.danger : AppColors.primary,
      ),
    );

    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombre,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 3),
        Text(zona, style: AppText.small),
      ],
    );

    Widget demora(CrossAxisAlignment alineacion) => Column(
      crossAxisAlignment: alineacion,
      children: [
        Text(
          '+${tramo.demoraMinutos} min',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: esAlta ? AppColors.danger : AppColors.warning,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          esAlta ? 'Congestión Alta' : 'Congestión Media',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );

    final boton = OutlinedButton(
      onPressed: onVerMapa,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: const Text('Ver mapa'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: esCelular
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    icono,
                    const SizedBox(width: 12),
                    Expanded(child: textos),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    demora(CrossAxisAlignment.start),
                    const Spacer(),
                    boton,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                icono,
                const SizedBox(width: 14),
                Expanded(child: textos),
                const SizedBox(width: 12),
                demora(CrossAxisAlignment.end),
                const SizedBox(width: 16),
                boton,
              ],
            ),
    );
  }
}
