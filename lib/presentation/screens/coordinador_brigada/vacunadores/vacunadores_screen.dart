import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/usuario.dart';
import '../../../providers/sector_provider.dart';

// Provider para vacunadores por sector
final vacunadoresPorSectorProvider =
    StreamProvider.family<List<Usuario>, String>((ref, sectorId) {
  return ref
      .read(usuarioRepositoryProvider)
      .obtenerVacunadoresPorSector(sectorId);
});

class VacunadoresScreen extends ConsumerWidget {
  final String sectorId;
  const VacunadoresScreen({super.key, required this.sectorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectorAsync = ref.watch(sectorPorIdProvider(sectorId));
    final vacunadoresAsync = ref.watch(vacunadoresPorSectorProvider(sectorId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: sectorAsync.when(
          data: (s) => Text('Vacunadores — ${s?.nombre ?? ''}'),
          loading: () => const Text('Vacunadores'),
          error: (_, __) => const Text('Vacunadores'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vacunadores/nuevo',
            extra: sectorId),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo vacunador'),
      ),
      body: vacunadoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vacunadores) => vacunadores.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No hay vacunadores en este sector',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vacunadores.length,
                itemBuilder: (_, i) =>
                    _TarjetaVacunador(
                      vacunador: vacunadores[i],
                      sectorId: sectorId,
                      ref: ref,
                    ),
              ),
      ),
    );
  }
}

class _TarjetaVacunador extends StatelessWidget {
  final Usuario vacunador;
  final String sectorId;
  final WidgetRef ref;

  const _TarjetaVacunador({
    required this.vacunador,
    required this.sectorId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            vacunador.nombres.isNotEmpty
                ? vacunador.nombres[0].toUpperCase()
                : 'V',
            style: TextStyle(
                color: Colors.green.shade700, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(vacunador.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vacunador.correo,
                style: const TextStyle(fontSize: 12)),
            Text('Cédula: ${vacunador.cedula}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'reasignar', child: Text('Reasignar sector')),
            const PopupMenuItem(
              value: 'quitar',
              child: Text('Quitar del sector',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (value) {
            if (value == 'quitar') {
              _confirmarQuitar(context);
            } else if (value == 'reasignar') {
              _mostrarReasignar(context);
            }
          },
        ),
      ),
    );
  }

  void _confirmarQuitar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar vacunador'),
        content: Text(
            '¿Quitar a ${vacunador.nombreCompleto} de este sector?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref
                  .read(sectorRepositoryProvider)
                  .desasignarVacunador(sectorId, vacunador.uid);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }

  void _mostrarReasignar(BuildContext context) {
    final sectoresAsync = ref.read(sectoresStreamProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reasignar a ${vacunador.nombres}'),
        content: sectoresAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (sectores) => SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sectores.length,
              itemBuilder: (_, i) {
                final s = sectores[i];
                if (s.id == sectorId) return const SizedBox.shrink();
                return ListTile(
                  title: Text(s.nombre),
                  subtitle: Text(s.ciudad),
                  onTap: () async {
                    // Quitar del sector actual y agregar al nuevo
                    await ref
                        .read(sectorRepositoryProvider)
                        .desasignarVacunador(sectorId, vacunador.uid);
                    await ref
                        .read(sectorRepositoryProvider)
                        .asignarVacunador(s.id, vacunador.uid);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
        ],
      ),
    );
  }
}