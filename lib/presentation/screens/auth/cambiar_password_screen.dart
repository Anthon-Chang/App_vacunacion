import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class CambiarPasswordScreen extends ConsumerStatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  ConsumerState<CambiarPasswordScreen> createState() =>
      _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState
    extends ConsumerState<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  String? _error;
  bool _exito = false;

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.cambiarContrasena(_nuevaCtrl.text.trim());

      setState(() => _exito = true);
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      final usuario = await repo.getCurrentUsuario();
      if (!mounted) return;

      switch (usuario?.rol) {
        case 'coordinador_campana':
          context.go('/dashboard-campana');
        case 'coordinador_brigada':
          context.go('/dashboard-brigada');
        default:
          context.go('/dashboard-vacunador');
      }
    } catch (e) {
      setState(() => _error = 'No se pudo cambiar la contraseña. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.lock_reset_rounded, size: 64, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Cambio de contraseña',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Es tu primer ingreso.\nDebes crear una nueva contraseña.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _exito
                        ? _buildExito()
                        : Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Nueva contraseña
                                TextFormField(
                                  controller: _nuevaCtrl,
                                  obscureText: _obscureNueva,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Nueva contraseña',
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureNueva
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined),
                                      onPressed: () => setState(
                                          () => _obscureNueva = !_obscureNueva),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Ingresa una contraseña';
                                    }
                                    if (v.length < 8) {
                                      return 'Mínimo 8 caracteres';
                                    }
                                    if (!v.contains(RegExp(r'[A-Z]'))) {
                                      return 'Debe tener al menos una mayúscula';
                                    }
                                    if (!v.contains(RegExp(r'[0-9]'))) {
                                      return 'Debe tener al menos un número';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),

                                // Indicador de fuerza
                                _buildFuerzaIndicador(_nuevaCtrl.text),
                                const SizedBox(height: 16),

                                // Confirmar contraseña
                                TextFormField(
                                  controller: _confirmarCtrl,
                                  obscureText: _obscureConfirmar,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _cambiar(),
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar contraseña',
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirmar
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined),
                                      onPressed: () => setState(() =>
                                          _obscureConfirmar = !_obscureConfirmar),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Confirma tu contraseña';
                                    }
                                    if (v != _nuevaCtrl.text) {
                                      return 'Las contraseñas no coinciden';
                                    }
                                    return null;
                                  },
                                ),

                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: AppTheme.error),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _loading ? null : _cambiar,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Cambiar contraseña'),
                                ),
                              ],
                            ),
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

  Widget _buildFuerzaIndicador(String pass) {
    int fuerza = 0;
    if (pass.length >= 8) fuerza++;
    if (pass.contains(RegExp(r'[A-Z]'))) fuerza++;
    if (pass.contains(RegExp(r'[0-9]'))) fuerza++;
    if (pass.contains(RegExp(r'[!@#$%^&*]'))) fuerza++;

    final colores = [Colors.red, Colors.orange, Colors.yellow, Colors.green];
    final textos = ['Muy débil', 'Débil', 'Buena', 'Fuerte'];

    if (pass.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              height: 4,
              decoration: BoxDecoration(
                color: i < fuerza ? colores[fuerza - 1] : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text(
          textos[fuerza > 0 ? fuerza - 1 : 0],
          style: TextStyle(
            fontSize: 12,
            color: fuerza > 0 ? colores[fuerza - 1] : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildExito() {
    return const Column(
      children: [
            Icon(Icons.check_circle_rounded,
            color: AppTheme.success, size: 64),
            SizedBox(height: 16),
            Text(
          '¡Contraseña actualizada!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.success,
          ),
        ),
          SizedBox(height: 8),
          Text(
          'Redirigiendo al dashboard...',
          style: TextStyle(color: Colors.grey),
        ),
          SizedBox(height: 16),
          CircularProgressIndicator(),
      ],
    );
  }
}