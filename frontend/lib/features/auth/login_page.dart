import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui.dart';
import 'auth_shell.dart';

/// Pantalla de inicio de sesión. Por ahora no valida contra el backend:
/// solo comprueba que los campos tengan un formato razonable.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _entrar() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.ubicacion);
    }
  }

  void _continuarComoAnonimo() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.ubicacion);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BIENVENIDO A PIURAGO', style: AppText.eyebrow),
            const SizedBox(height: 14),
            const Text('Inicia sesión', style: AppText.title),
            const SizedBox(height: 10),
            const Text(
              'Consulta cómo llegar y cuándo pasará tu próxima combi.',
              style: AppText.body,
            ),
            const SizedBox(height: 28),
            const Text('Correo electrónico', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              decoration: appInputDecoration(
                hint: 'nombre@correo.com',
                icon: Icons.mail_outline,
              ),
              validator: (valor) {
                final texto = (valor ?? '').trim();
                if (!texto.contains('@') || !texto.contains('.')) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text('Contraseña', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contrasena,
              obscureText: true,
              decoration: appInputDecoration(
                hint: '••••••••',
                icon: Icons.lock_outline,
              ),
              validator: (valor) {
                if ((valor ?? '').isEmpty) return 'Ingresa tu contraseña';
                return null;
              },
              onFieldSubmitted: (_) => _entrar(),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _entrar,
              style: appFilledButtonStyle(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Iniciar sesión'),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SeparadorConTexto(texto: 'o inicia sesión con:'),
            const SizedBox(height: 14),
            _AccesoAlternativo(
              onCorreoInstitucional: () => mostrarProximamente(
                context,
                'El acceso con correo institucional',
              ),
              onGoogle: () =>
                  mostrarProximamente(context, 'El acceso con Google'),
            ),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    '¿No tienes una cuenta? ',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  InkWell(
                    onTap: () => mostrarProximamente(context, 'El registro'),
                    child: const Text(
                      'Regístrate aquí',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _continuarComoAnonimo,
                style: TextButton.styleFrom(foregroundColor: AppColors.text),
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Continuar como pasajero anónimo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeparadorConTexto extends StatelessWidget {
  const _SeparadorConTexto({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(texto, style: AppText.small),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _AccesoAlternativo extends StatelessWidget {
  const _AccesoAlternativo({
    required this.onCorreoInstitucional,
    required this.onGoogle,
  });

  final VoidCallback onCorreoInstitucional;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(23),
              onTap: onCorreoInstitucional,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline, size: 16, color: AppColors.text),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Correo institucional',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(23),
              onTap: onGoogle,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'G',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cuenta de Google',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
