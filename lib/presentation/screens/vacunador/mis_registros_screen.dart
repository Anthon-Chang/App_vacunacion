import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/vacunacion.dart';
import '../../providers/vacunacion_provider.dart';

class MisRegistrosScreen extends ConsumerWidget {
  final String vacunadorId;
  const MisRegistrosScreen({super.key, required this.vacunadorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrosAsync =
        ref.watch(vacunacionesPorVacunadorProvider(vacunadorId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        title: const Text('Mis registros'),
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
                    Text('No tienes registros aún',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: registros.length,
                itemBuilder: (_, i) =>
                    _TarjetaRegistroVacunador(vacunacion: registros[i]),
              ),
      ),
    );
  }
}

class _TarjetaRegistroVacunador extends StatelessWidget {
  final Vacunacion vacunacion;
  const _TarjetaRegistroVacunador({required this.vacunacion});

  @override
  Widget build(BuildContext context) {
    final fecha =
        DateFormat('dd/MM/yyyy HH:mm').format(vacunacion.fechaHora);
    final esMascota = vacunacion.tipoMascota == 'perro';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              esMascota ? Colors.brown.shade50 : Colors.orange.shade50,
          child: Text(
            esMascota ? '🐶' : '🐱',
            style: const TextStyle(fontSize: 22),
          ),
        ),
        title: Text(
          '${vacunacion.nombreMascota} — ${vacunacion.propietarioNombre}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vacunacion.vacunaAplicada,
                style: const TextStyle(fontSize: 12)),
            Text(fecha,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!vacunacion.sincronizado)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.sync_disabled,
                    color: Colors.orange, size: 18),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF4A148C)),
              onPressed: () => context.push(
                '/editar-vacunacion/${vacunacion.id}',
                extra: vacunacion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}