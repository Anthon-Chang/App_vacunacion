import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/sector.dart';
import '../../../providers/sector_provider.dart';

class FormSectorScreen extends ConsumerStatefulWidget {
  final Sector? sectorEditar;

  const FormSectorScreen({super.key, this.sectorEditar});

  @override
  ConsumerState<FormSectorScreen> createState() => _FormSectorScreenState();
}

class _FormSectorScreenState extends ConsumerState<FormSectorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _parroquiaCtrl = TextEditingController();
  final _zonaCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _esEdicion => widget.sectorEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreCtrl.text = widget.sectorEditar!.nombre;
      _parroquiaCtrl.text = widget.sectorEditar!.ciudad;
      _zonaCtrl.text = widget.sectorEditar!.descripcion;
    } else {
      _parroquiaCtrl.text = 'Quito';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _parroquiaCtrl.dispose();
    _zonaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(sectorRepositoryProvider);

      if (_esEdicion) {
        await repo.actualizar(widget.sectorEditar!.id, {
          'nombre': _nombreCtrl.text.trim(),
          'parroquia': _parroquiaCtrl.text.trim(),
          'zona': _zonaCtrl.text.trim(),
          'ciudad': _parroquiaCtrl.text.trim(),
        });
      } else {
        final sector = Sector(
          id: '',
          nombre: _nombreCtrl.text.trim(),
          ciudad: _parroquiaCtrl.text.trim(),
          descripcion: _zonaCtrl.text.trim(),
        );
        await repo.crear(sector);
      }

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'No se pudo guardar. Intenta de nuevo.');
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
        title: Text(_esEdicion ? 'Editar sector' : 'Nuevo sector'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del sector *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _parroquiaCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Parroquia *',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _zonaCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Zona *',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo requerido' : null,
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
                    onPressed: _loading ? null : _guardar,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(_esEdicion ? 'Guardar cambios' : 'Crear sector'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}