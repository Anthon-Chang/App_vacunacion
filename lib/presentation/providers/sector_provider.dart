import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/sector_repository.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../domain/entities/sector.dart';
import '../../domain/entities/usuario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final sectorRepositoryProvider = Provider<SectorRepository>((ref) {
  return SectorRepository();
});

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return UsuarioRepository();
});

final sectoresStreamProvider = StreamProvider<List<Sector>>((ref) {
  return ref.read(sectorRepositoryProvider).obtenerTodos();
});

final coordinadoresBrigadaProvider = StreamProvider<List<Usuario>>((ref) {
  return ref.read(usuarioRepositoryProvider).obtenerCoordinadoresBrigada();
});

// Provider para obtener un sector por ID
final sectorPorIdProvider =
    StreamProvider.family<Sector?, String>((ref, sectorId) {
  return ref
      .read(sectorRepositoryProvider)
      .obtenerPorId(sectorId);
});

final todosVacunadoresProvider = StreamProvider<List<Usuario>>((ref) {
  return FirebaseFirestore.instance
      .collection('usuarios')
      .where('rol', isEqualTo: 'vacunador')
      .snapshots()
      .map((s) => s.docs
          .map((d) => Usuario.fromMap(d.id, d.data()))
          .toList());
});

Future<List<Sector>> obtenerTodosUnaVez() async {
  final snap = await FirebaseFirestore.instance.collection('sectores').orderBy('nombre').get();
  return snap.docs.map((d) => Sector.fromMap(d.id, d.data())).toList();
}