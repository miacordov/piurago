import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_shell.dart';

/// Marco de las pantallas internas. En pantallas anchas muestra barra lateral
/// y barra superior; en angostas, un menú desplegable.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.seccion, required this.child});

  final SeccionApp seccion;
  final Widget child;

  static const double anchoMinimoEscritorio = 760;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= anchoMinimoEscritorio) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 220, child: SideNav(seccion: seccion)),
                Expanded(
                  child: Column(
                    children: [
                      const TopBar(),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: const Border(bottom: BorderSide(color: AppColors.border)),
            title: const BrandLogo(),
            actions: const [
              Padding(padding: EdgeInsets.only(right: 16), child: UserAvatar()),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(child: SideNav(seccion: seccion)),
          ),
          body: child,
        );
      },
    );
  }
}
