import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui.dart';
import '../../data/api/auth_service.dart';
import 'auth_shell.dart';

/// Pantalla de acceso: inicia sesión o crea una cuenta contra el backend
/// (AuthService), o entra como pasajero anónimo. Sin [authService] (pruebas
/// y modo demo) solo comprueba el formato de los campos y avanza.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();

  /// true: formulario de registro; false: inicio de sesión.
  bool _registrando = false;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _avanzar() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.ubicacion);
  }

  Future<void> _entrar() async {
    if (_enviando || !(_formKey.currentState?.validate() ?? false)) return;
    final auth = widget.authService;
    if (auth == null) return _avanzar();

    setState(() {
      _enviando = true;
      _error = null;
    });
    final correo = _correo.text.trim();
    final ok = _registrando
        ? await auth.registrar(_nombre.text.trim(), correo, _contrasena.text)
        : await auth.login(correo, _contrasena.text);
    if (!mounted) return;
    if (ok) return _avanzar();
    setState(() {
      _enviando = false;
      _error = auth.ultimoFalloFueDeRed
          ? 'No pudimos conectar con el servidor. Revisa tu conexión e '
                'inténtalo de nuevo.'
          : _registrando
          ? 'No pudimos crear la cuenta. Puede que ese correo ya esté '
                'registrado.'
          : 'Correo o contraseña incorrectos.';
    });
  }

  /// Pide el token anónimo; si el servidor no responde, entra igual (la app
  /// funciona con datos de demostración).
  Future<void> _continuarComoAnonimo() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    await widget.authService?.obtenerToken();
    if (mounted) _avanzar();
  }

  void _cambiarModo() {
    setState(() {
      _registrando = !_registrando;
      _error = null;
    });
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
            Text(
              _registrando ? 'Crea tu cuenta' : 'Inicia sesión',
              style: AppText.title,
            ),
            const SizedBox(height: 10),
            const Text(
              'Consulta cómo llegar y cuándo pasará tu próxima combi.',
              style: AppText.body,
            ),
            const SizedBox(height: 28),
            if (_registrando) ...[
              const Text('Nombre', style: AppText.label),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('campo-nombre'),
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: appInputDecoration(
                  hint: 'Tu nombre',
                  icon: Icons.person_outline,
                ),
                validator: (valor) =>
                    (valor ?? '').trim().isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 18),
            ],
            const Text('Correo electrónico', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('campo-correo'),
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
              key: const ValueKey('campo-contrasena'),
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
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _enviando ? null : _entrar,
              style: appFilledButtonStyle(),
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_registrando ? 'Crear cuenta' : 'Iniciar sesión'),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 18),
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
                  Text(
                    _registrando
                        ? '¿Ya tienes una cuenta? '
                        : '¿No tienes una cuenta? ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  InkWell(
                    onTap: _cambiarModo,
                    child: Text(
                      _registrando ? 'Inicia sesión aquí' : 'Regístrate aquí',
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
                onPressed: _enviando ? null : _continuarComoAnonimo,
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
