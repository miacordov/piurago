import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Marco común del inicio de sesión y de la activación de ubicación:
/// panel de color a la izquierda y contenido a la derecha. En pantallas
/// angostas el panel pasa a ser una franja arriba.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child});

  final Widget child;

  static const double _anchoMinimoDosColumnas = 760;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _anchoMinimoDosColumnas) {
            return Row(
              children: [
                const Expanded(flex: 9, child: _Hero(compacto: false)),
                Expanded(
                  flex: 11,
                  child: Container(
                    color: AppColors.background,
                    child: LayoutBuilder(
                      builder: (context, area) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(0, area.maxHeight - 80),
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                const _Hero(compacto: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.compacto});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    if (compacto) {
      return Container(
        width: double.infinity,
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_Marca(), SizedBox(height: 20), _Titular(tamano: 26)],
        ),
      );
    }
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.all(64),
      child: LayoutBuilder(
        builder: (context, area) {
          const textos = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [_Marca(), SizedBox(height: 28), _Titular(tamano: 40)],
          );
          // Si la ventana es muy baja, se omite la ilustración.
          if (area.maxHeight < 460) {
            return const SingleChildScrollView(child: textos);
          }
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textos,
              SizedBox(height: 24),
              Expanded(child: _Ilustracion()),
            ],
          );
        },
      ),
    );
  }
}

class _Titular extends StatelessWidget {
  const _Titular({required this.tamano});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Text(
        'Tu ruta por Piura, más clara y más cerca.',
        style: TextStyle(
          color: Colors.white,
          fontSize: tamano,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.directions_bus_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'PiuraGo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Ilustración de la ruta. Se reduce sola para caber en el espacio disponible.
class _Ilustracion extends StatelessWidget {
  const _Ilustracion();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 260,
              child: CustomPaint(painter: _RutaPainter()),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 110,
              child: Text(
                'Rutas en tiempo real',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja la ruta en forma de S con un círculo en cada extremo. Deja un
/// margen para que el trazo no quede pegado al borde.
class _RutaPainter extends CustomPainter {
  const _RutaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final trazo = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    final radio = w * 0.14;
    final arriba = Offset(w * 0.80, h * 0.16);
    final abajo = Offset(w * 0.17, h * 0.84);

    final camino = Path()
      ..moveTo(arriba.dx - radio, arriba.dy)
      ..lineTo(w * 0.32, arriba.dy)
      ..cubicTo(w * 0.04, arriba.dy, w * 0.04, h * 0.50, w * 0.32, h * 0.50)
      ..lineTo(w * 0.66, h * 0.50)
      ..cubicTo(w * 0.98, h * 0.50, w * 0.98, abajo.dy, w * 0.66, abajo.dy)
      ..lineTo(abajo.dx + radio, abajo.dy);

    canvas.drawPath(camino, trazo);
    canvas.drawCircle(arriba, radio, trazo);
    canvas.drawCircle(abajo, radio, trazo);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
