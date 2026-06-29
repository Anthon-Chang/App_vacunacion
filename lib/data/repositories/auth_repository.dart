import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/entities/usuario.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Usuario?> getCurrentUsuario() async {
    final user = _auth.currentUser;
    print('Usuario auth: ${user?.uid}');
    print('Base de datos: ${_db.databaseId}');
    if (user == null) return null;
    try {
      final doc = await _db.collection('usuarios').doc(user.uid).get();
      print('Documento existe: ${doc.exists}');
      print('Datos: ${doc.data()}');
      if (!doc.exists) return null;
      return Usuario.fromMap(user.uid, doc.data()!);
    } catch (e) {
      print('ERROR FIRESTORE: $e');
      return null;
    }
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<void> cambiarContrasena(String nuevaContrasena) async {
    await _auth.currentUser?.updatePassword(nuevaContrasena);
    final uid = _auth.currentUser!.uid;
    await _db.collection('usuarios').doc(uid).update({'primerIngreso': false});
  }

  Future<void> recuperarContrasena(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<String> crearUsuario({
    required String correo,
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String rol,
  }) async {
    // Guardar email y password del coordinador actual NO es posible
    // Usamos app secundaria para no afectar sesión
    
    FirebaseApp? appSecundaria;
    try {
      // Intentar obtener app existente o crear nueva
      try {
        appSecundaria = Firebase.app('secundaria');
      } catch (_) {
        appSecundaria = await Firebase.initializeApp(
          name: 'secundaria',
          options: Firebase.app().options,
        );
      }

      final authSecundario = FirebaseAuth.instanceFor(app: appSecundaria);

      final cred = await authSecundario.createUserWithEmailAndPassword(
        email: correo,
        password: 'Ecuador2026',
      );
      final uid = cred.user!.uid;

      await _db.collection('usuarios').doc(uid).set({
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefono,
        'correo': correo,
        'rol': rol,
        'sectorIds': [],
        'primerIngreso': true,
      });

      await authSecundario.signOut();
      return uid;

    } finally {
      // No eliminamos la app para reutilizarla
    }
  }
}