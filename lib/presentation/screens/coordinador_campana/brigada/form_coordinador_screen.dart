import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class FormCoordinadorScreen extends ConsumerStatefulWidget {
  const FormCoordinadorScreen({super.key});

  @override
  ConsumerState<FormCoordinadorScreen> createState() =>
      _FormCoordinadorScreenState();
}

class _FormCoordinadorScreenState extends ConsumerState<FormCoordinadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _exito = false;

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(authRepositoryProvider).crearUsuario(
        correo: _correoCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        rol: 'coordinador_brigada',
      );
      setState(() => _exito = true);
    } catch (e) {
      setState(() {
        _error = e.toString().contains('email-already-in-use')
            ? 'Este correo ya está registrado.'
            : 'Error al crear el usuario. Intenta de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Nuevo Coordinador de Brigada'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _exito ? _buildExito(context) : _buildFormulario(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Datos del coordinador',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('La contraseña inicial será: Ecuador2026',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          _campo(_cedulaCtrl, 'Cédula *', Icons.badge_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v.length != 10) return 'La cédula debe tener 10 dígitos';
                return null;
              }),
          const SizedBox(height: 14),
          _campo(_nombresCtrl, 'Nombres *', Icons.person_outlined),
          const SizedBox(height: 14),
          _campo(_apellidosCtrl, 'Apellidos *', Icons.person_outlined),
          const SizedBox(height: 14),
          _campo(_telefonoCtrl, 'Teléfono *', Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v.length < 9) return 'Teléfono inválido';
                return null;
              }),
          const SizedBox(height: 14),
          _campo(_correoCtrl, 'Correo electrónico *', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (!v.contains('@')) return 'Correo inválido';
                return null;
              }),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: AppTheme.error)),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _crear,
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Crear coordinador'),
          ),
        ],
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icono, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
      ),
      validator: validator ??
          (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _buildExito(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppTheme.success, size: 64),
        const SizedBox(height: 16),
        const Text('¡Coordinador creado!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.success)),
        const SizedBox(height: 8),
        const Text(
          'Se envió la contraseña inicial Ecuador2026.\nEl usuario deberá cambiarla en su primer ingreso.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('Volver'),
        ),
      ],
    );
  }
}