import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../repositories/vacunacion_local_repository.dart';

class SyncService {
  final _localRepo = VacunacionLocalRepository();
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Verificar conectividad
  Future<bool> tieneConexion() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Sincronizar pendientes
  Future<int> sincronizarPendientes() async {
    if (!await tieneConexion()) return 0;

    final pendientes = await _localRepo.obtenerPendientes();
    int sincronizados = 0;

    for (final v in pendientes) {
      try {
        String? fotoUrl;

        // Subir foto si existe localmente
        if (v.fotoPath != null && File(v.fotoPath!).existsSync()) {
          final ref = _storage.ref().child('vacunaciones/${v.id}.jpg');
          await ref.putFile(File(v.fotoPath!));
          fotoUrl = await ref.getDownloadURL();
        }

        // Subir a Firestore
        await _db.collection('vacunaciones').doc(v.id).set({
          'propietarioNombre': v.propietarioNombre,
          'propietarioCedula': v.propietarioCedula,
          'propietarioTelefono': v.propietarioTelefono,
          'tipoMascota': v.tipoMascota,
          'nombreMascota': v.nombreMascota,
          'edadAproximada': v.edadAproximada,
          'sexo': v.sexo,
          'vacunaAplicada': v.vacunaAplicada,
          'observaciones': v.observaciones,
          'fotoUrl': fotoUrl,
          'latitud': v.latitud,
          'longitud': v.longitud,
          'fechaHora': v.fechaHora,
          'sectorId': v.sectorId,
          'vacunadorId': v.vacunadorId,
          'sincronizado': true,
        });

        // Marcar como sincronizada localmente
        await _localRepo.marcarSincronizada(v.id!);
        sincronizados++;
      } catch (e) {
        // Si falla uno, continuar con el siguiente
        continue;
      }
    }

    return sincronizados;
  }

  // Escuchar cambios de conectividad y sincronizar automáticamente
  Stream<int> escucharYSincronizar() {
    return Connectivity().onConnectivityChanged.asyncMap((result) async {
      if (result != ConnectivityResult.none) {
        return await sincronizarPendientes();
      }
      return 0;
    });
  }
}