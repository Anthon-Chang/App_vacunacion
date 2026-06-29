import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sector.dart';

class SectorRepository {
    final _db = FirebaseFirestore.instance;

  // Crear sector
Future<void> crear(Sector sector) async {
  await _db.collection('sectores').add({
    'nombre': sector.nombre,
    'parroquia': sector.ciudad,
    'zona': sector.descripcion,
    'ciudad': sector.ciudad,
    'activo': true,
    'coordinadorId': null,
  });
}

  // Actualizar sector
  Future<void> actualizar(String id, Map<String, dynamic> datos) async {
    await _db.collection('sectores').doc(id).update(datos);
  }

  // Eliminar sector
  Future<void> eliminar(String id) async {
    await _db.collection('sectores').doc(id).delete();
  }

  // Obtener todos los sectores (stream en tiempo real)
  Stream<List<Sector>> obtenerTodos() {
    return _db
        .collection('sectores')
        .snapshots()
        .map((snap) {
          final sectores = snap.docs
              .map((d) => Sector.fromMap(d.id, d.data()))
              .toList();
          // Ordenar en memoria en lugar de en Firestore
          sectores.sort((a, b) => a.nombre.compareTo(b.nombre));
          return sectores;
        });
  }

  // Asignar coordinador a sector
  Future<void> asignarCoordinador(String sectorId, String coordinadorId) async {
    // Actualizar el sector
    await _db.collection('sectores').doc(sectorId).update({
      'coordinadorId': coordinadorId,
    });
    // Agregar sectorId al usuario
    await _db.collection('usuarios').doc(coordinadorId).update({
      'sectorIds': FieldValue.arrayUnion([sectorId]),
    });
  }

  // Desasignar coordinador de sector
  Future<void> desasignarCoordinador(String sectorId, String coordinadorId) async {
    await _db.collection('sectores').doc(sectorId).update({
      'coordinadorId': null,
    });
    await _db.collection('usuarios').doc(coordinadorId).update({
      'sectorIds': FieldValue.arrayRemove([sectorId]),
    });
  }

  // Obtener sector por ID (stream)
  Stream<Sector?> obtenerPorId(String id) {
    return _db.collection('sectores').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Sector.fromMap(doc.id, doc.data()!);
    });
  }

  // Asignar vacunador a sector
  Future<void> asignarVacunador(String sectorId, String vacunadorId) async {
    await _db.collection('usuarios').doc(vacunadorId).update({
      'sectorIds': FieldValue.arrayUnion([sectorId]),
    });
  }

  // Desasignar vacunador de sector
  Future<void> desasignarVacunador(String sectorId, String vacunadorId) async {
    await _db.collection('usuarios').doc(vacunadorId).update({
      'sectorIds': FieldValue.arrayRemove([sectorId]),
    });
  }
}