import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/usuario.dart';
import '../../../providers/sector_provider.dart';

class CoordinadoresScreen extends ConsumerWidget {
  const CoordinadoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinadoresAsync = ref.watch(coordinadoresBrigadaProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Coordinadores de Brigada'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/coordinadores/nuevo'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo coordinador'),
      ),
      body: coordinadoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (coordinadores) => coordinadores.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No hay coordinadores creados',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: coordinadores.length,
                itemBuilder: (_, i) =>
                    _TarjetaCoordinador(coordinador: coordinadores[i]),
              ),
      ),
    );
  }
}

class _TarjetaCoordinador extends StatelessWidget {
  final Usuario coordinador;
  const _TarjetaCoordinador({required this.coordinador});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            coordinador.nombres.isNotEmpty
                ? coordinador.nombres[0].toUpperCase()
                : 'C',
            style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(coordinador.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(coordinador.correo,
                style: const TextStyle(fontSize: 12)),
            Text('Cédula: ${coordinador.cedula}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: coordinador.sectorIds.isEmpty
            ? const Chip(label: Text('Sin sector'))
            : Chip(
                label: Text('${coordinador.sectorIds.length} sector(es)'),
                backgroundColor: Colors.blue.shade50,
              ),
      ),
    );
  }
}