import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sector_provider.dart';
import '../../providers/vacunacion_provider.dart';
import 'widgets/grafica_por_sector.dart';
import 'widgets/grafica_por_vacunador.dart';
import 'widgets/grafica_tipo_mascota.dart';
import 'widgets/tarjeta_stat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardEstadisticasScreen extends ConsumerWidget {
  const DashboardEstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(currentUsuarioProvider);

    return usuarioAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (usuario) {
        if (usuario == null) return const SizedBox.shrink();

        // Coordinador campaña → global; brigada → su sector
        final esCampana = usuario.rol == 'coordinador_campana';
        final sectorId =
            usuario.sectorIds.isNotEmpty ? usuario.sectorIds.first : '';

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            title: const Text('Dashboard'),
          ),
          body: esCampana
              ? _DashboardGlobal()
              : _DashboardSector(sectorId: sectorId),
        );
      },
    );
  }
}

// ── DASHBOARD GLOBAL (Coordinador Campaña) ────────────────
class _DashboardGlobal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(estadisticasGlobalProvider);
    final sectoresAsync = ref.watch(sectoresStreamProvider);

    // Necesitamos los nombres de vacunadores
    final vacunadoresAsync = ref.watch(todosVacunadoresProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        final sectores = sectoresAsync.asData?.value ?? [];
        final vacunadores = vacunadoresAsync.asData?.value ?? [];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(estadisticasGlobalProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Tarjetas resumen ──
              const Text('Resumen general',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: [
                  TarjetaStat(
                    titulo: 'Total vacunaciones',
                    valor: stats.totalVacunaciones.toString(),
                    icono: Icons.vaccines,
                    color: AppTheme.primary,
                  ),
                  TarjetaStat(
                    titulo: 'Perros vacunados',
                    valor: stats.perros.toString(),
                    icono: Icons.pets,
                    color: const Color(0xFF6D4C41),
                    subtitulo: '🐶',
                  ),
                  TarjetaStat(
                    titulo: 'Gatos vacunados',
                    valor: stats.gatos.toString(),
                    icono: Icons.catching_pokemon,
                    color: const Color(0xFFEF6C00),
                    subtitulo: '🐱',
                  ),
                  TarjetaStat(
                    titulo: 'Pendientes sync',
                    valor: stats.pendientesSincronizacion.toString(),
                    icono: Icons.sync_disabled,
                    color: stats.pendientesSincronizacion > 0
                        ? Colors.orange
                        : Colors.green,
                    subtitulo: stats.pendientesSincronizacion > 0
                        ? 'Offline'
                        : 'Al día',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Gráfica tipo mascota ──
              GraficaTipoMascota(
                  perros: stats.perros, gatos: stats.gatos),

              const SizedBox(height: 16),

              // ── Gráfica por sector ──
              if (stats.porSector.isNotEmpty)
                GraficaPorSector(
                  porSector: stats.porSector,
                  sectores: sectores,
                ),

              const SizedBox(height: 16),

              // ── Gráfica por vacunador ──
              if (stats.porVacunador.isNotEmpty)
                GraficaPorVacunador(
                  porVacunador: stats.porVacunador,
                  vacunadores: vacunadores,
                ),

              // ── Tabla detalle por sector ──
              const SizedBox(height: 24),
              const Text('Detalle por sector',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _TablaSectores(
                  porSector: stats.porSector, sectores: sectores),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── DASHBOARD POR SECTOR (Coordinador Brigada) ────────────
class _DashboardSector extends ConsumerWidget {
  final String sectorId;
  const _DashboardSector({required this.sectorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync =
        ref.watch(estadisticasPorSectorProvider(sectorId));
    final sectorAsync = ref.watch(sectorPorIdProvider(sectorId));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(estadisticasPorSectorProvider(sectorId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Nombre del sector
              sectorAsync.when(
                data: (s) => Text(
                  s?.nombre ?? 'Mi sector',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: [
                  TarjetaStat(
                    titulo: 'Total vacunaciones',
                    valor: stats.totalVacunaciones.toString(),
                    icono: Icons.vaccines,
                    color: const Color(0xFF1B5E20),
                  ),
                  TarjetaStat(
                    titulo: 'Perros',
                    valor: stats.perros.toString(),
                    icono: Icons.pets,
                    color: const Color(0xFF6D4C41),
                    subtitulo: '🐶',
                  ),
                  TarjetaStat(
                    titulo: 'Gatos',
                    valor: stats.gatos.toString(),
                    icono: Icons.catching_pokemon,
                    color: const Color(0xFFEF6C00),
                    subtitulo: '🐱',
                  ),
                  TarjetaStat(
                    titulo: 'Pendientes',
                    valor: stats.pendientesSincronizacion.toString(),
                    icono: Icons.sync_disabled,
                    color: stats.pendientesSincronizacion > 0
                        ? Colors.orange
                        : Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              GraficaTipoMascota(
                  perros: stats.perros, gatos: stats.gatos),
              const SizedBox(height: 16),

              if (stats.porVacunador.isNotEmpty)
                _TablaVacunadores(
                    porVacunador: stats.porVacunador),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── TABLA DETALLE SECTORES ────────────────────────────────
class _TablaSectores extends StatelessWidget {
  final Map<String, int> porSector;
  final List sectores;

  const _TablaSectores(
      {required this.porSector, required this.sectores});

  @override
  Widget build(BuildContext context) {
    final entradas = porSector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 3,
      child: Column(
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(
                    child: Text('Sector',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold))),
                Text('Vacunaciones',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...entradas.map((e) {
            final sector = sectores.cast<dynamic>().firstWhere(
              (s) => s.id == e.key,
              orElse: () => null,
            );
            final nombre = sector?.nombre ?? e.key;
            final total = porSector.values
                .fold(0, (acc, v) => acc + v);
            final pct = total > 0
                ? ((e.value / total) * 100).toStringAsFixed(1)
                : '0';

            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: total > 0 ? e.value / total : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${e.value}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text('$pct%',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── TABLA VACUNADORES ────────────────────────────────────
class _TablaVacunadores extends ConsumerWidget {
  final Map<String, int> porVacunador;
  const _TablaVacunadores({required this.porVacunador});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entradas = porVacunador.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total =
        porVacunador.values.fold(0, (acc, v) => acc + v);

    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Text('Rendimiento por vacunador',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          ...entradas.map((e) {
            final pct = total > 0
                ? ((e.value / total) * 100).toStringAsFixed(1)
                : '0';
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(e.key)
                  .get(),
              builder: (context, snap) {
                String nombre = 'Vacunador';
                if (snap.hasData && snap.data!.exists) {
                  final data = snap.data!.data()!;
                  nombre = data['nombres'] ?? 'Vacunador';
                }
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            Colors.green.shade100,
                        child: Text(
                          nombre.isNotEmpty
                              ? nombre[0].toUpperCase()
                              : 'V',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            LinearProgressIndicator(
                              value: total > 0
                                  ? e.value / total
                                  : 0,
                              backgroundColor:
                                  Colors.grey.shade200,
                              valueColor:
                                  const AlwaysStoppedAnimation
                                          <Color>(
                                      Color(0xFF1B5E20)),
                              minHeight: 4,
                              borderRadius:
                                  BorderRadius.circular(2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text('${e.value}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('$pct%',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}