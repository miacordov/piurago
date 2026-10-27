import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';

/// Secciones de la barra lateral.
enum SeccionApp { rutas, mapa, congestion }

/// Logo y nombre de la aplicación.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: AppColors.primary,
          child: Icon(
            Icons.directions_bus_outlined,
            size: 18,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 10),
        Flexible(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
              children: [
                TextSpan(text: 'Piura'),
                TextSpan(
                  text: 'Go',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Barra lateral con las secciones de la aplicación.
class SideNav extends StatelessWidget {
  const SideNav({super.key, required this.seccion});

  final SeccionApp seccion;

  void _ir(BuildContext context, String ruta) {
    Navigator.of(context).pushReplacementNamed(ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 26, 22, 26),
            child: BrandLogo(),
          ),
          const Divider(height: 1, color: AppColors.border),
          const Padding(
            padding: EdgeInsets.fromLTRB(26, 28, 26, 10),
            child: Text(
              'EXPLORAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ),
          _NavItem(
            icon: Icons.alt_route,
            label: 'Rutas',
            selected: seccion == SeccionApp.rutas,
            onTap: () => _ir(context, AppRoutes.rutas),
          ),
          _NavItem(
            icon: Icons.map_outlined,
            label: 'Mapa',
            selected: seccion == SeccionApp.mapa,
            onTap: () => _ir(context, AppRoutes.mapa),
          ),
          _NavItem(
            icon: Icons.traffic,
            label: 'Congestión',
            selected: seccion == SeccionApp.congestion,
            onTap: () => _ir(context, AppRoutes.congestion),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra superior de pantallas anchas: ubicación, modo demostración (solo
/// con datos de prueba) y perfil.
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.esDemostracion = false});

  final bool esDemostracion;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 77,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Piura, Perú',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textMuted,
          ),
          const Spacer(),
          if (esDemostracion) ...[
            const DemoPill(),
            const SizedBox(width: 12),
          ],
          const UserAvatar(),
        ],
      ),
    );
  }
}

/// Aviso de que la app muestra datos de prueba.
class DemoPill extends StatelessWidget {
  const DemoPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: AppColors.success),
          SizedBox(width: 8),
          Text(
            'Modo demostración',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.blueTile,
      child: Icon(Icons.person_outline, size: 18, color: AppColors.primary),
    );
  }
}
