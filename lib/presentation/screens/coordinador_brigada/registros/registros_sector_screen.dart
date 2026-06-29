import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/vacunacion.dart';
import '../../../providers/sector_provider.dart';
import '../../../providers/vacunacion_provider.dart';

class RegistrosSectorScreen extends ConsumerWidget {
  final String sectorId;
  const RegistrosSectorScreen({super.key, required this.sectorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectorAsync = ref.watch(sectorPorIdProvider(sectorId));
    final registrosAsync = ref.watch(vacunacionesPorSectorProvider(sectorId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: sectorAsync.when(
          data: (s) => Text('Registros — ${s?.nombre ?? ''}'),
          loading: () => const Text('Registros'),
          error: (_, __) => const Text('Registros'),
        ),
      ),
      body: registrosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (registros) => registros.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No hay registros en este sector',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: registros.length,
                itemBuilder: (_, i) => _TarjetaRegistro(
                  vacunacion: registros[i],
                  sectorId: sectorId,
                ),
              ),
      ),
    );
  }
}

class _TarjetaRegistro extends ConsumerWidget {
  final Vacunacion vacunacion;
  final String sectorId;

  const _TarjetaRegistro({
    required this.vacunacion,
    required this.sectorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = DateFormat('dd/MM/yyyy HH:mm')
        .format(vacunacion.fechaHora);
    final esMascota = vacunacion.tipoMascota == 'perro';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              esMascota ? Colors.brown.shade100 : Colors.orange.shade100,
          child: Text(
            esMascota ? '🐶' : '🐱',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          '${vacunacion.nombreMascota} — ${vacunacion.propietarioNombre}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(fecha,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!vacunacion.sincronizado)
              const Icon(Icons.sync_disabled, color: Colors.orange, size: 18),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              onPressed: () => context.push(
                  '/editar-vacunacion/${vacunacion.id}',
                  extra: vacunacion),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                _fila('Cédula propietario', vacunacion.propietarioCedula),
                _fila('Teléfono', vacunacion.propietarioTelefono),
                _fila('Mascota', '${vacunacion.tipoMascota} — ${vacunacion.sexo}'),
                _fila('Edad', vacunacion.edadAproximada),
                _fila('Vacuna', vacunacion.vacunaAplicada),
                if (vacunacion.observaciones.isNotEmpty)
                  _fila('Observaciones', vacunacion.observaciones),
                _fila('GPS',
                    '${vacunacion.latitud.toStringAsFixed(5)}, ${vacunacion.longitud.toStringAsFixed(5)}'),
                if (vacunacion.fotoUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      vacunacion.fotoUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}