import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

import '../../providers/auth_provider.dart';
import '../../providers/sector_provider.dart';


class DashboardBrigadaScreen extends ConsumerWidget {
  const DashboardBrigadaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(currentUsuarioProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Coordinador de Brigada'),
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
      body: usuarioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (usuario) {
          if (usuario == null) return const SizedBox.shrink();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(currentUsuarioProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bienvenida
                  _buildBienvenida(usuario.nombreCompleto),
                  const SizedBox(height: 20),

                  // Sectores asignados
                  const Text('Mis sectores',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  usuario.sectorIds.isEmpty
                      ? _buildSinSectores()
                      : _buildListaSectores(context, ref, usuario.sectorIds),

                  const SizedBox(height: 24),

                  // Acciones rápidas
                  const Text('Acciones rápidas',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildAcciones(context, usuario.sectorIds),
                ],
              ),
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
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
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
          const Text('Coordinador de Brigada',
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

  Widget _buildListaSectores(
      BuildContext context, WidgetRef ref, List<String> sectorIds) {
    return Column(
      children: sectorIds.map((id) {
        final sectorAsync = ref.watch(sectorPorIdProvider(id));
        return sectorAsync.when(
          loading: () => const Card(
              child: ListTile(title: Text('Cargando...'))),
          error: (_, __) => const SizedBox.shrink(),
          data: (sector) {
            if (sector == null) return const SizedBox.shrink();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1B5E20),
                  child: Icon(Icons.location_on,
                      color: Colors.white, size: 18),
                ),
                title: Text(sector.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(sector.ciudad),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people_outlined,
                          color: AppTheme.primary),
                      tooltip: 'Ver vacunadores',
                      onPressed: () =>
                          context.push('/vacunadores/${sector.id}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.list_alt_outlined,
                          color: Colors.orange),
                      tooltip: 'Ver registros',
                      onPressed: () =>
                          context.push('/registros-sector/${sector.id}'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildAcciones(BuildContext context, List<String> sectorIds) {
    return Column(
      children: [
        _TarjetaAccion(
          icono: Icons.person_add_outlined,
          titulo: 'Crear Vacunador',
          subtitulo: 'Registrar nuevo vacunador',
          color: Colors.green,
          onTap: () => context.push('/vacunadores/nuevo'),
        ),
        _TarjetaAccion(
          icono: Icons.edit_note_outlined,
          titulo: 'Registros de vacunación',
          subtitulo: 'Ver y corregir registros de mis sectores',
          color: Colors.orange,
          onTap: () => sectorIds.isNotEmpty
              ? context.push('/registros-sector/${sectorIds.first}')
              : null,
        ),
        _TarjetaAccion(
          icono: Icons.bar_chart_outlined,
          titulo: 'Dashboard de mi sector',
          subtitulo: 'Estadísticas de vacunación',
          color: Colors.blue,
          onTap: () => context.push('/dashboard-estadisticas'),
        ),
      ],
    );
  }
}

class _TarjetaAccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback? onTap;

  const _TarjetaAccion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: color),
        ),
        title: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitulo,
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}