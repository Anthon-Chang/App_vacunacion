import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/sector.dart';
import '../../../../domain/entities/usuario.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/sector_provider.dart';

class FormVacunadorScreen extends ConsumerStatefulWidget {
  final String? sectorIdInicial;
  const FormVacunadorScreen({super.key, this.sectorIdInicial});

  @override
  ConsumerState<FormVacunadorScreen> createState() =>
      _FormVacunadorScreenState();
}

class _FormVacunadorScreenState extends ConsumerState<FormVacunadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  String? _sectorSeleccionado;
  bool _loading = false;
  String? _error;
  bool _exito = false;

  // Guardamos los datos del coordinador al inicio
  Usuario? _coordinadorActual;
  List<Sector> _sectoresDisponibles = [];

  @override
  void initState() {
    super.initState();
    _sectorSeleccionado = widget.sectorIdInicial;
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final usuario = await ref.read(authRepositoryProvider).getCurrentUsuario();
    final sectores = await obtenerTodosUnaVez();
    if (mounted) {
      setState(() {
        _coordinadorActual = usuario;
        _sectoresDisponibles = sectores
            .where((s) => usuario!.sectorIds.contains(s.id))
            .toList();
      });
    }
  }

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
    if (_sectorSeleccionado == null) {
      setState(() => _error = 'Selecciona un sector');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(authRepositoryProvider);
      final sectorRepo = ref.read(sectorRepositoryProvider);

      final uid = await repo.crearUsuario(
        correo: _correoCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        rol: 'vacunador',
      );

      await sectorRepo.asignarVacunador(_sectorSeleccionado!, uid);

      // Restaurar sesión del coordinador
      if (_coordinadorActual != null) {
        ref.invalidate(currentUsuarioProvider);
      }

      setState(() => _exito = true);
    } catch (e) {
      setState(() {
        _error = e.toString().contains('email-already-in-use')
            ? 'Este correo ya está registrado.'
            : 'Error al crear el vacunador: ${e.toString()}';
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
        title: const Text('Nuevo Vacunador'),
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
          const Text('Datos del vacunador',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Contraseña inicial: Ecuador2026',
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
          const SizedBox(height: 14),

          // Selector de sector con datos precargados
          if (_sectoresDisponibles.isEmpty)
            const CircularProgressIndicator()
          else
            DropdownButtonFormField<String>(
              value: _sectorSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Sector *',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: _sectoresDisponibles
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nombre),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _sectorSeleccionado = v),
              validator: (v) => v == null ? 'Selecciona un sector' : null,
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
                : const Text('Crear vacunador'),
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
        const Text('¡Vacunador creado!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.success)),
        const SizedBox(height: 8),
        const Text(
          'Contraseña inicial: Ecuador2026\nEl vacunador deberá cambiarla en su primer ingreso.',
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