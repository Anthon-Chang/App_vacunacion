import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sector.dart';
import '../../../domain/entities/vacunacion.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sector_provider.dart';
import '../../providers/vacunacion_provider.dart';
import '../../../data/local/vacunacion_local.dart';
import '../../../data/repositories/vacunacion_local_repository.dart';
import '../../../data/repositories/sector_repository.dart';
import '../../../data/services/sync_service.dart';

class FormVacunacionScreen extends ConsumerStatefulWidget {
  final Vacunacion? vacunacionEditar;
  const FormVacunacionScreen({super.key, this.vacunacionEditar});

  @override
  ConsumerState<FormVacunacionScreen> createState() =>
      _FormVacunacionScreenState();
}

class _FormVacunacionScreenState extends ConsumerState<FormVacunacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _propNombreCtrl = TextEditingController();
  final _propCedulaCtrl = TextEditingController();
  final _propTelefonoCtrl = TextEditingController();
  final _mascNombreCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _vacunaCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  String _tipoMascota = 'perro';
  String _sexo = 'macho';
  String? _sectorSeleccionado;
  List<Sector> _sectoresDisponibles = [];

  Position? _posicion;
  File? _foto;
  bool _cargandoGPS = false;
  bool _loading = false;
  String? _error;
  bool _exito = false;

  bool get _esEdicion => widget.vacunacionEditar != null;

  final List<String> _vacunas = [
    'Antirrábica',
    'Parvovirus',
    'Moquillo',
    'Hepatitis',
    'Leptospirosis',
    'Bordatella',
    'Pentavalente',
    'Sexavalente',
  ];
  String? _vacunaSeleccionada;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) _cargarDatosEdicion();
    _cargarSectores();
  }

  Future<void> _cargarSectores() async {
    try {
      final usuario =
          await ref.read(authRepositoryProvider).getCurrentUsuario();
      final sectores = await ref
          .read(sectorRepositoryProvider)
          .obtenerTodos()
          .first;
      if (mounted) {
        setState(() {
          _sectoresDisponibles = sectores
              .where((s) => usuario!.sectorIds.contains(s.id))
              .toList();
        });
      }
    } catch (e) {
      print('Error cargando sectores: $e');
    }
  }

  void _cargarDatosEdicion() {
    final v = widget.vacunacionEditar!;
    _propNombreCtrl.text = v.propietarioNombre;
    _propCedulaCtrl.text = v.propietarioCedula;
    _propTelefonoCtrl.text = v.propietarioTelefono;
    _mascNombreCtrl.text = v.nombreMascota;
    _edadCtrl.text = v.edadAproximada;
    _observacionesCtrl.text = v.observaciones;
    _tipoMascota = v.tipoMascota;
    _sexo = v.sexo;
    _sectorSeleccionado = v.sectorId;
    _vacunaSeleccionada = v.vacunaAplicada;
  }

  @override
  void dispose() {
    _propNombreCtrl.dispose();
    _propCedulaCtrl.dispose();
    _propTelefonoCtrl.dispose();
    _mascNombreCtrl.dispose();
    _edadCtrl.dispose();
    _vacunaCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    setState(() { _cargandoGPS = true; _error = null; });
    try {
      final repo = ref.read(vacunacionRepositoryProvider);
      final pos = await repo.obtenerUbicacion();
      setState(() => _posicion = pos);
    } catch (e) {
      setState(() => _error = 'No se pudo obtener la ubicación: $e');
    } finally {
      setState(() => _cargandoGPS = false);
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final repo = ref.read(vacunacionRepositoryProvider);
      final foto = await repo.tomarFoto();
      if (foto != null) setState(() => _foto = foto);
    } catch (e) {
      setState(() => _error = 'No se pudo acceder a la cámara.');
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_posicion == null && !_esEdicion) {
      setState(() => _error = 'Debes capturar la ubicación GPS.');
      return;
    }
    if (_foto == null && !_esEdicion) {
      setState(() => _error = 'Debes tomar una fotografía.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final syncService = SyncService();
      final tieneConexion = await syncService.tieneConexion();
      print('=== TIENE CONEXION: $tieneConexion ===');

      final usuario =
          await ref.read(authRepositoryProvider).getCurrentUsuario();
      print('=== USUARIO: ${usuario?.uid} ===');

      if (_esEdicion) {
        final repo = ref.read(vacunacionRepositoryProvider);
        await repo.actualizar(widget.vacunacionEditar!.id!, {
          'propietarioNombre': _propNombreCtrl.text.trim(),
          'propietarioCedula': _propCedulaCtrl.text.trim(),
          'propietarioTelefono': _propTelefonoCtrl.text.trim(),
          'nombreMascota': _mascNombreCtrl.text.trim(),
          'edadAproximada': _edadCtrl.text.trim(),
          'tipoMascota': _tipoMascota,
          'sexo': _sexo,
          'vacunaAplicada': _vacunaSeleccionada,
          'observaciones': _observacionesCtrl.text.trim(),
        });
      } else if (tieneConexion) {
        print('=== GUARDANDO ONLINE ===');
        final repo = ref.read(vacunacionRepositoryProvider);
        final vacunacion = Vacunacion(
          propietarioNombre: _propNombreCtrl.text.trim(),
          propietarioCedula: _propCedulaCtrl.text.trim(),
          propietarioTelefono: _propTelefonoCtrl.text.trim(),
          tipoMascota: _tipoMascota,
          nombreMascota: _mascNombreCtrl.text.trim(),
          edadAproximada: _edadCtrl.text.trim(),
          sexo: _sexo,
          vacunaAplicada: _vacunaSeleccionada ?? '',
          observaciones: _observacionesCtrl.text.trim(),
          latitud: _posicion!.latitude,
          longitud: _posicion!.longitude,
          fechaHora: DateTime.now(),
          sectorId: _sectorSeleccionado ?? '',
          vacunadorId: usuario?.uid ?? '',
          sincronizado: true,
        );
        await repo.registrar(vacunacion, _foto);
      } else {
        print('=== GUARDANDO OFFLINE ===');
        final localRepo = VacunacionLocalRepository();
        final vacunacionLocal = VacunacionLocal(
          propietarioNombre: _propNombreCtrl.text.trim(),
          propietarioCedula: _propCedulaCtrl.text.trim(),
          propietarioTelefono: _propTelefonoCtrl.text.trim(),
          tipoMascota: _tipoMascota,
          nombreMascota: _mascNombreCtrl.text.trim(),
          edadAproximada: _edadCtrl.text.trim(),
          sexo: _sexo,
          vacunaAplicada: _vacunaSeleccionada ?? '',
          observaciones: _observacionesCtrl.text.trim(),
          fotoPath: _foto?.path,
          latitud: _posicion!.latitude,
          longitud: _posicion!.longitude,
          fechaHora: DateTime.now(),
          sectorId: _sectorSeleccionado ?? '',
          vacunadorId: usuario?.uid ?? '',
          sincronizado: false,
        );
        final id = await localRepo.guardar(vacunacionLocal);
        print('=== GUARDADO OFFLINE CON ID: $id ===');
      }

      setState(() => _exito = true);
    } catch (e, stack) {
      print('=== ERROR: $e ===');
      print('=== STACK: $stack ===');
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        title: Text(_esEdicion ? 'Editar vacunación' : 'Nueva vacunación'),
      ),
      body: _exito
          ? _buildExito()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeccion('Datos del propietario', Icons.person),
                    _buildCard([
                      _campo(_propNombreCtrl, 'Nombre del propietario *',
                          Icons.person_outlined),
                      const SizedBox(height: 14),
                      _campo(_propCedulaCtrl, 'Cédula del propietario *',
                          Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Campo requerido';
                            if (v.length != 10) return 'Debe tener 10 dígitos';
                            return null;
                          }),
                      const SizedBox(height: 14),
                      _campo(_propTelefonoCtrl, 'Teléfono *',
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                    ]),

                    const SizedBox(height: 16),
                    _buildSeccion('Datos de la mascota', Icons.pets),
                    _buildCard([
                      const Text('Tipo de mascota *',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _BotonSeleccion(
                              label: '🐶 Perro',
                              seleccionado: _tipoMascota == 'perro',
                              onTap: () =>
                                  setState(() => _tipoMascota = 'perro'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BotonSeleccion(
                              label: '🐱 Gato',
                              seleccionado: _tipoMascota == 'gato',
                              onTap: () =>
                                  setState(() => _tipoMascota = 'gato'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _campo(_mascNombreCtrl, 'Nombre de la mascota *',
                          Icons.pets_outlined),
                      const SizedBox(height: 14),
                      _campo(_edadCtrl, 'Edad aproximada *',
                          Icons.cake_outlined,
                          hint: 'Ej: 2 años, 6 meses'),
                      const SizedBox(height: 14),
                      const Text('Sexo *',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _BotonSeleccion(
                              label: 'Macho',
                              seleccionado: _sexo == 'macho',
                              onTap: () => setState(() => _sexo = 'macho'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BotonSeleccion(
                              label: 'Hembra',
                              seleccionado: _sexo == 'hembra',
                              onTap: () => setState(() => _sexo = 'hembra'),
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 16),
                    _buildSeccion('Vacuna aplicada', Icons.vaccines),
                    _buildCard([
                      DropdownButtonFormField<String>(
                        value: _vacunaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Vacuna *',
                          prefixIcon: Icon(Icons.vaccines_outlined),
                        ),
                        items: _vacunas
                            .map((v) => DropdownMenuItem(
                                value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _vacunaSeleccionada = v),
                        validator: (v) =>
                            v == null ? 'Selecciona una vacuna' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _observacionesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ]),

                    if (!_esEdicion) ...[
                      const SizedBox(height: 16),
                      _buildSeccion('Sector', Icons.map),
                      _buildCard([_buildSelectorSector()]),
                    ],

                    const SizedBox(height: 16),
                    _buildSeccion('Fotografía *', Icons.camera_alt),
                    _buildCard([_buildCamara()]),

                    const SizedBox(height: 16),
                    _buildSeccion('Ubicación GPS *', Icons.gps_fixed),
                    _buildCard([_buildGPS()]),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppTheme.error)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_esEdicion
                              ? 'Guardar cambios'
                              : 'Registrar vacunación'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeccion(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 18, color: const Color(0xFF4A148C)),
          const SizedBox(width: 6),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C))),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icono, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icono),
      ),
      validator: validator ??
          (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _buildSelectorSector() {
    if (_sectoresDisponibles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Cargando sectores...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: _sectorSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Sector *',
        prefixIcon: Icon(Icons.map_outlined),
      ),
      items: _sectoresDisponibles
          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre)))
          .toList(),
      onChanged: (v) => setState(() => _sectorSeleccionado = v),
      validator: (v) => v == null ? 'Selecciona un sector' : null,
    );
  }

  Widget _buildCamara() {
    return Column(
      children: [
        if (_foto != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _foto!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
        ] else
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('Sin fotografía', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _tomarFoto,
          icon: const Icon(Icons.camera_alt),
          label: Text(_foto == null ? 'Tomar fotografía' : 'Tomar otra'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }

  Widget _buildGPS() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_posicion != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text('Ubicación capturada',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Lat: ${_posicion!.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13)),
                Text('Lng: ${_posicion!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13)),
                Text(
                    'Precisión: ${_posicion!.accuracy.toStringAsFixed(1)} m',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        ElevatedButton.icon(
          onPressed: _cargandoGPS ? null : _obtenerUbicacion,
          icon: _cargandoGPS
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.gps_fixed),
          label: Text(_cargandoGPS
              ? 'Obteniendo ubicación...'
              : _posicion == null
                  ? 'Capturar ubicación GPS'
                  : 'Actualizar ubicación'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }

  Widget _buildExito() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 80),
            const SizedBox(height: 16),
            Text(
              _esEdicion ? '¡Registro actualizado!' : '¡Vacunación registrada!',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success),
            ),
            const SizedBox(height: 8),
            const Text(
              'El registro se guardó correctamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 12),
            if (!_esEdicion)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _exito = false;
                    _foto = null;
                    _posicion = null;
                    _formKey.currentState?.reset();
                    _propNombreCtrl.clear();
                    _propCedulaCtrl.clear();
                    _propTelefonoCtrl.clear();
                    _mascNombreCtrl.clear();
                    _edadCtrl.clear();
                    _observacionesCtrl.clear();
                    _tipoMascota = 'perro';
                    _sexo = 'macho';
                    _vacunaSeleccionada = null;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Registrar otra vacunación'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BotonSeleccion extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonSeleccion({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF4A148C) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF4A148C)
                : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: seleccionado ? Colors.white : Colors.grey.shade700,
              fontWeight:
                  seleccionado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}