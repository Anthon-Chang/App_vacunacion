import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/vacunacion_repository.dart';
import '../../domain/entities/vacunacion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final vacunacionRepositoryProvider = Provider<VacunacionRepository>((ref) {
  return VacunacionRepository();
});

final vacunacionesPorSectorProvider =
    StreamProvider.family<List<Vacunacion>, String>((ref, sectorId) {
  return ref.read(vacunacionRepositoryProvider).porSector(sectorId);
});

final vacunacionesPorVacunadorProvider =
    StreamProvider.family<List<Vacunacion>, String>((ref, vacunadorId) {
  return ref.read(vacunacionRepositoryProvider).porVacunador(vacunadorId);
});

// Modelo de estadísticas
class EstadisticasDashboard {
  final int totalVacunaciones;
  final int perros;
  final int gatos;
  final Map<String, int> porSector;      // sectorId -> cantidad
  final Map<String, int> porVacunador;   // vacunadorId -> cantidad
  final int pendientesSincronizacion;

  const EstadisticasDashboard({
    required this.totalVacunaciones,
    required this.perros,
    required this.gatos,
    required this.porSector,
    required this.porVacunador,
    required this.pendientesSincronizacion,
  });
}

// Provider global (coordinador campaña)
final estadisticasGlobalProvider =
    StreamProvider<EstadisticasDashboard>((ref) {
  return FirebaseFirestore.instance
      .collection('vacunaciones')
      .snapshots()
      .map((snap) {
    final docs = snap.docs;
    final porSector = <String, int>{};
    final porVacunador = <String, int>{};
    int perros = 0, gatos = 0, pendientes = 0;

    for (final doc in docs) {
      final data = doc.data();
      if (data['tipoMascota'] == 'perro') perros++;
      if (data['tipoMascota'] == 'gato') gatos++;
      if (data['sincronizado'] == false) pendientes++;

      final sId = data['sectorId'] as String? ?? '';
      porSector[sId] = (porSector[sId] ?? 0) + 1;

      final vId = data['vacunadorId'] as String? ?? '';
      porVacunador[vId] = (porVacunador[vId] ?? 0) + 1;
    }

    return EstadisticasDashboard(
      totalVacunaciones: docs.length,
      perros: perros,
      gatos: gatos,
      porSector: porSector,
      porVacunador: porVacunador,
      pendientesSincronizacion: pendientes,
    );
  });
});

// Provider por sector (coordinador brigada)
final estadisticasPorSectorProvider =
    StreamProvider.family<EstadisticasDashboard, String>((ref, sectorId) {
  return FirebaseFirestore.instance
      .collection('vacunaciones')
      .where('sectorId', isEqualTo: sectorId)
      .snapshots()
      .map((snap) {
    final docs = snap.docs;
    final porVacunador = <String, int>{};
    int perros = 0, gatos = 0, pendientes = 0;

    for (final doc in docs) {
      final data = doc.data();
      if (data['tipoMascota'] == 'perro') perros++;
      if (data['tipoMascota'] == 'gato') gatos++;
      if (data['sincronizado'] == false) pendientes++;
      final vId = data['vacunadorId'] as String? ?? '';
      porVacunador[vId] = (porVacunador[vId] ?? 0) + 1;
    }

    return EstadisticasDashboard(
      totalVacunaciones: docs.length,
      perros: perros,
      gatos: gatos,
      porSector: {sectorId: docs.length},
      porVacunador: porVacunador,
      pendientesSincronizacion: pendientes,
    );
  });
});