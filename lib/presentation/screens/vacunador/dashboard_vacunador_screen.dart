import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sector_provider.dart';
import '../../providers/vacunacion_provider.dart';

class DashboardVacunadorScreen extends ConsumerWidget {
  const DashboardVacunadorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(currentUsuarioProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        title: const Text('Vacunador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/nueva-vacunacion'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar vacunación'),
      ),
      body: usuarioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (usuario) {
          if (usuario == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bienvenida
                _buildBienvenida(usuario.nombreCompleto),
                const SizedBox(height: 20),

                // Mis sectores asignados
                const Text('Mis sectores',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                usuario.sectorIds.isEmpty
                    ? _buildSinSectores()
                    : Column(
                        children: usuario.sectorIds
                            .map((id) => _TarjetaSectorVacunador(
                                sectorId: id, vacunadorId: usuario.uid))
                            .toList(),
                      ),

                const SizedBox(height: 24),
                const Text('Mis registros recientes',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _ResumenVacunador(vacunadorId: usuario.uid),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBienvenida(String nombre) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bienvenido/a',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(nombre,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Vacunador',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSinSectores() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No tienes sectores asignados aún.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _TarjetaSectorVacunador extends ConsumerWidget {
  final String sectorId;
  final String vacunadorId;
  const _TarjetaSectorVacunador(
      {required this.sectorId, required this.vacunadorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectorAsync = ref.watch(sectorPorIdProvider(sectorId));
    final registrosAsync =
        ref.watch(vacunacionesPorSectorProvider(sectorId));

    return sectorAsync.when(
      loading: () => const Card(child: ListTile(title: Text('Cargando...'))),
      error: (_, __) => const SizedBox.shrink(),
      data: (sector) {
        if (sector == null) return const SizedBox.shrink();
        final total = registrosAsync.when(
          data: (list) => list
              .where((v) => v.vacunadorId == vacunadorId)
              .length
              .toString(),
          loading: () => '...',
          error: (_, __) => '—',
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF4A148C),
              child: Icon(Icons.location_on, color: Colors.white, size: 18),
            ),
            title: Text(sector.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(sector.ciudad),
            trailing: Chip(
              label: Text('$total registros'),
              backgroundColor: Colors.purple.shade50,
            ),
          ),
        );
      },
    );
  }
}

class _ResumenVacunador extends ConsumerWidget {
  final String vacunadorId;
  const _ResumenVacunador({required this.vacunadorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrosAsync =
        ref.watch(vacunacionesPorVacunadorProvider(vacunadorId));

    return registrosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (registros) {
        final perros =
            registros.where((v) => v.tipoMascota == 'perro').length;
        final gatos =
            registros.where((v) => v.tipoMascota == 'gato').length;
        final pendientes =
            registros.where((v) => !v.sincronizado).length;

        return Column(
          children: [
            Row(
              children: [
                _MiniCard('Total', registros.length.toString(),
                    Icons.vaccines, Colors.purple),
                const SizedBox(width: 10),
                _MiniCard('Perros', perros.toString(),
                    Icons.pets, Colors.brown),
                const SizedBox(width: 10),
                _MiniCard('Gatos', gatos.toString(),
                    Icons.catching_pokemon, Colors.orange),
              ],
            ),
            if (pendientes > 0) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_disabled,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text('$pendientes registros pendientes de sincronización',
                        style: const TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  context.push('/mis-registros/$vacunadorId'),
              icon: const Icon(Icons.list_alt),
              label: const Text('Ver todos mis registros'),
            ),
          ],
        );
      },
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _MiniCard(this.titulo, this.valor, this.icono, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, color: color, size: 24),
              const SizedBox(height: 4),
              Text(valor,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}