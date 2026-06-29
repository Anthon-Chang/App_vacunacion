import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      
      // Cerrar sesión anterior
      await repo.signOut();
      
      // Invalidar el provider de usuario para limpiar caché
      ref.invalidate(currentUsuarioProvider);
      
      // Pequeña pausa para que Firebase procese el logout
      await Future.delayed(const Duration(milliseconds: 500));
      
      await repo.signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      final usuario = await repo.getCurrentUsuario();
      if (usuario == null || !mounted) return;

      if (usuario.primerIngreso) {
        context.go('/cambiar-password');
        return;
      }

      switch (usuario.rol) {
        case 'coordinador_campana':
          context.go('/dashboard-campana');
        case 'coordinador_brigada':
          context.go('/dashboard-brigada');
        default:
          context.go('/dashboard-vacunador');
      }
    } catch (e) {
      setState(() => _error = _mensajeError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  String _mensajeError(String error) {
    return error.replaceFirst(RegExp(r'^.*?:\s*'), '');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.vaccines, size: 64, color: Color(0xFF1565C0)),
                    const SizedBox(height: 8),
                    const Text('Vacunación Canina y Felina',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Ingresar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/recuperar-password'),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}