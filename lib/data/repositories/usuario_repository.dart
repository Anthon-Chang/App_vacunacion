import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usuario.dart';


class UsuarioRepository {
    final _db = FirebaseFirestore.instance;

  // Obtener coordinadores de brigada
  Stream<List<Usuario>> obtenerCoordinadoresBrigada() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'coordinador_brigada')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Usuario.fromMap(d.id, d.data()))
            .toList());
  }

  // Obtener vacunadores de un sector
  Stream<List<Usuario>> obtenerVacunadoresPorSector(String sectorId) {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'vacunador')
        .where('sectorIds', arrayContains: sectorId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Usuario.fromMap(d.id, d.data()))
            .toList());
  }

  // Obtener usuario por uid
  Future<Usuario?> obtenerPorUid(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return Usuario.fromMap(doc.id, doc.data()!);
  }

  // Actualizar datos de usuario
  Future<void> actualizar(String uid, Map<String, dynamic> datos) async {
    await _db.collection('usuarios').doc(uid).update(datos);
  }
}