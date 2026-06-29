class Vacunacion {
  final String? id;
  final String propietarioNombre;
  final String propietarioCedula;
  final String propietarioTelefono;
  final String tipoMascota; // perro | gato
  final String nombreMascota;
  final String edadAproximada;
  final String sexo; // macho | hembra
  final String vacunaAplicada;
  final String observaciones;
  final String? fotoUrl;
  final double latitud;
  final double longitud;
  final DateTime fechaHora;
  final String sectorId;
  final String vacunadorId;
  final bool sincronizado;

  const Vacunacion({
    this.id,
    required this.propietarioNombre,
    required this.propietarioCedula,
    required this.propietarioTelefono,
    required this.tipoMascota,
    required this.nombreMascota,
    required this.edadAproximada,
    required this.sexo,
    required this.vacunaAplicada,
    this.observaciones = '',
    this.fotoUrl,
    required this.latitud,
    required this.longitud,
    required this.fechaHora,
    required this.sectorId,
    required this.vacunadorId,
    this.sincronizado = false,
  });

  factory Vacunacion.fromMap(String id, Map<String, dynamic> map) {
    return Vacunacion(
      id: id,
      propietarioNombre: map['propietarioNombre'] ?? '',
      propietarioCedula: map['propietarioCedula'] ?? '',
      propietarioTelefono: map['propietarioTelefono'] ?? '',
      tipoMascota: map['tipoMascota'] ?? 'perro',
      nombreMascota: map['nombreMascota'] ?? '',
      edadAproximada: map['edadAproximada'] ?? '',
      sexo: map['sexo'] ?? 'macho',
      vacunaAplicada: map['vacunaAplicada'] ?? '',
      observaciones: map['observaciones'] ?? '',
      fotoUrl: map['fotoUrl'],
      latitud: (map['latitud'] ?? 0.0).toDouble(),
      longitud: (map['longitud'] ?? 0.0).toDouble(),
      fechaHora: (map['fechaHora'] as dynamic).toDate(),
      sectorId: map['sectorId'] ?? '',
      vacunadorId: map['vacunadorId'] ?? '',
      sincronizado: map['sincronizado'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'propietarioNombre': propietarioNombre,
    'propietarioCedula': propietarioCedula,
    'propietarioTelefono': propietarioTelefono,
    'tipoMascota': tipoMascota,
    'nombreMascota': nombreMascota,
    'edadAproximada': edadAproximada,
    'sexo': sexo,
    'vacunaAplicada': vacunaAplicada,
    'observaciones': observaciones,
    'fotoUrl': fotoUrl,
    'latitud': latitud,
    'longitud': longitud,
    'fechaHora': fechaHora,
    'sectorId': sectorId,
    'vacunadorId': vacunadorId,
    'sincronizado': sincronizado,
  };
}