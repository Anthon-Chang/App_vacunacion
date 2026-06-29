import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/sector.dart';
import '../../../providers/sector_provider.dart';

class SectoresScreen extends ConsumerWidget {
  const SectoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectoresAsync = ref.watch(sectoresStreamProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Sectores'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sectores/nuevo'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo sector'),
      ),
      body: sectoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 8),
              Text('Error: $e'),
            ],
          ),
        ),
        data: (sectores) => sectores.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No hay sectores creados',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sectores.length,
                itemBuilder: (_, i) => _TarjetaSector(sector: sectores[i]),
              ),
      ),
    );
  }
}

class _TarjetaSector extends ConsumerWidget {
  final Sector sector;
  const _TarjetaSector({required this.sector});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
        title: Text(sector.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sector.ciudad),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'editar', child: Text('Editar')),
            const PopupMenuItem(value: 'asignar', child: Text('Asignar coordinador')),
            const PopupMenuItem(
              value: 'eliminar',
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'editar':
                context.push('/sectores/editar/${sector.id}');
              case 'asignar':
                _mostrarDialogoAsignar(context, ref, sector);
              case 'eliminar':
                _confirmarEliminar(context, ref, sector);
            }
          },
        ),
      ),
    );
  }

  void _mostrarDialogoAsignar(
      BuildContext context, WidgetRef ref, Sector sector) {
    final coordinadoresAsync = ref.read(coordinadoresBrigadaProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Asignar coordinador'),
        content: coordinadoresAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (coordinadores) => coordinadores.isEmpty
              ? const Text('No hay coordinadores disponibles')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: coordinadores.length,
                    itemBuilder: (_, i) {
                      final c = coordinadores[i];
                      return ListTile(
                        title: Text(c.nombreCompleto),
                        subtitle: Text(c.correo),
                        onTap: () async {
                          await ref
                              .read(sectorRepositoryProvider)
                              .asignarCoordinador(sector.id, c.uid);
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
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, Sector sector) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar sector'),
        content: Text('¿Eliminar "${sector.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(sectorRepositoryProvider).eliminar(sector.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}