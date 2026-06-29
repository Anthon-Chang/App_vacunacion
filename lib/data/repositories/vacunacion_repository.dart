import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/vacunacion.dart';

class VacunacionRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  Future<Position> obtenerUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS desactivado');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<File?> tomarFoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<String> subirFoto(File foto, String vacunacionId) async {
    final ref = _storage.ref().child('vacunaciones/$vacunacionId.jpg');
    await ref.putFile(foto);
    return await ref.getDownloadURL();
  }

  Future<void> registrar(Vacunacion v, File? foto) async {
    final id = const Uuid().v4();
    String? fotoUrl;

    if (foto != null) {
      fotoUrl = await subirFoto(foto, id);
    }

    final data = v.toMap()..['fotoUrl'] = fotoUrl..['sincronizado'] = true;
    await _db.collection('vacunaciones').doc(id).set(data);
  }

  Future<void> actualizar(String id, Map<String, dynamic> cambios) async {
    await _db.collection('vacunaciones').doc(id).update(cambios);
  }

  Stream<List<Vacunacion>> porSector(String sectorId) {
    return _db
        .collection('vacunaciones')
        .where('sectorId', isEqualTo: sectorId)
        .orderBy('fechaHora', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Vacunacion.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<Vacunacion>> porVacunador(String vacunadorId) {
    return _db
        .collection('vacunaciones')
        .where('vacunadorId', isEqualTo: vacunadorId)
        .orderBy('fechaHora', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Vacunacion.fromMap(d.id, d.data()))
            .toList());
  }
}