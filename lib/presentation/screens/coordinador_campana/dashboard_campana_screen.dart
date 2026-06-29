import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sector_provider.dart';

class DashboardCampanaScreen extends ConsumerWidget {
  const DashboardCampanaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectoresAsync = ref.watch(sectoresStreamProvider);
    final coordinadoresAsync = ref.watch(coordinadoresBrigadaProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Coordinador de Campaña'),
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
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(sectoresStreamProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenida
              _buildBienvenida(ref),
              const SizedBox(height: 20),

              // Tarjetas de resumen
              _buildResumen(sectoresAsync, coordinadoresAsync),
              const SizedBox(height: 24),

              // Acciones rápidas
              const Text(
                'Acciones rápidas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAcciones(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBienvenida(WidgetRef ref) {
    final usuarioAsync = ref.watch(currentUsuarioProvider);
    return usuarioAsync.when(
      data: (usuario) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bienvenido/a',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            Text(
              usuario?.nombreCompleto ?? 'Coordinador',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Coordinador de Campaña',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 80,
          child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildResumen(AsyncValue sectoresAsync, AsyncValue coordinadoresAsync) {
    return Row(
      children: [
        Expanded(
          child: _TarjetaResumen(
            icono: Icons.map_outlined,
            color: Colors.blue,
            titulo: 'Sectores',
            valor: sectoresAsync.when(
              data: (list) => list.length.toString(),
              loading: () => '...',
              error: (_, __) => '—',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TarjetaResumen(
            icono: Icons.people_outlined,
            color: Colors.green,
            titulo: 'Coordinadores',
            valor: coordinadoresAsync.when(
              data: (list) => list.length.toString(),
              loading: () => '...',
              error: (_, __) => '—',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcciones(BuildContext context) {
    final acciones = [
      _Accion(
        icono: Icons.add_location_alt_outlined,
        titulo: 'Gestionar Sectores',
        subtitulo: 'Crear y editar sectores',
        color: Colors.blue,
        onTap: () => context.push('/sectores'),
      ),
      _Accion(
        icono: Icons.person_add_outlined,
        titulo: 'Coordinadores de Brigada',
        subtitulo: 'Crear y asignar coordinadores',
        color: Colors.green,
        onTap: () => context.push('/coordinadores'),
      ),
      _Accion(
        icono: Icons.bar_chart_outlined,
        titulo: 'Ver Dashboard General',
        subtitulo: 'Estadísticas de vacunación',
        color: Colors.orange,
        onTap: () => context.push('/dashboard-estadisticas'),
      ),
    ];

    return Column(
      children: acciones.map((a) => _buildTarjetaAccion(a)).toList(),
    );
  }

  Widget _buildTarjetaAccion(_Accion accion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: accion.onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accion.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(accion.icono, color: accion.color),
        ),
        title: Text(accion.titulo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(accion.subtitulo,
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;

  const _TarjetaResumen({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 8),
            Text(valor,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(titulo,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Accion {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  _Accion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });
}