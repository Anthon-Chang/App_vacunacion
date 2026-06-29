class Usuario {
  final String uid;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String correo;
  final String rol; // coordinador_campana | coordinador_brigada | vacunador
  final List<String> sectorIds;
  final bool primerIngreso;

  const Usuario({
    required this.uid,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.correo,
    required this.rol,
    required this.sectorIds,
    required this.primerIngreso,
  });

  String get nombreCompleto => '$nombres $apellidos';

  factory Usuario.fromMap(String uid, Map<String, dynamic> map) {
    return Usuario(
      uid: uid,
      cedula: map['cedula'] ?? '',
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      rol: map['rol'] ?? 'vacunador',
      sectorIds: List<String>.from(map['sectorIds'] ?? []),
      primerIngreso: map['primerIngreso'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'cedula': cedula,
    'nombres': nombres,
    'apellidos': apellidos,
    'telefono': telefono,
    'correo': correo,
    'rol': rol,
    'sectorIds': sectorIds,
    'primerIngreso': primerIngreso,
  };
}