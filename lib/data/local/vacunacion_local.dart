
class VacunacionLocal {
  String? id;
  String propietarioNombre;
  String propietarioCedula;
  String propietarioTelefono;
  String tipoMascota;
  String nombreMascota;
  String edadAproximada;
  String sexo;
  String vacunaAplicada;
  String observaciones;
  String? fotoPath;
  double latitud;
  double longitud;
  DateTime fechaHora;
  String sectorId;
  String vacunadorId;
  bool sincronizado;

  VacunacionLocal({
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
    this.fotoPath,
    required this.latitud,
    required this.longitud,
    required this.fechaHora,
    required this.sectorId,
    required this.vacunadorId,
    this.sincronizado = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'propietarioNombre': propietarioNombre,
    'propietarioCedula': propietarioCedula,
    'propietarioTelefono': propietarioTelefono,
    'tipoMascota': tipoMascota,
    'nombreMascota': nombreMascota,
    'edadAproximada': edadAproximada,
    'sexo': sexo,
    'vacunaAplicada': vacunaAplicada,
    'observaciones': observaciones,
    'fotoPath': fotoPath,
    'latitud': latitud,
    'longitud': longitud,
    'fechaHora': fechaHora.millisecondsSinceEpoch,
    'sectorId': sectorId,
    'vacunadorId': vacunadorId,
    'sincronizado': sincronizado,
  };

  factory VacunacionLocal.fromMap(Map<dynamic, dynamic> map) {
    return VacunacionLocal(
      id: map['id'],
      propietarioNombre: map['propietarioNombre'] ?? '',
      propietarioCedula: map['propietarioCedula'] ?? '',
      propietarioTelefono: map['propietarioTelefono'] ?? '',
      tipoMascota: map['tipoMascota'] ?? 'perro',
      nombreMascota: map['nombreMascota'] ?? '',
      edadAproximada: map['edadAproximada'] ?? '',
      sexo: map['sexo'] ?? 'macho',
      vacunaAplicada: map['vacunaAplicada'] ?? '',
      observaciones: map['observaciones'] ?? '',
      fotoPath: map['fotoPath'],
      latitud: (map['latitud'] ?? 0.0).toDouble(),
      longitud: (map['longitud'] ?? 0.0).toDouble(),
      fechaHora: DateTime.fromMillisecondsSinceEpoch(map['fechaHora'] ?? 0),
      sectorId: map['sectorId'] ?? '',
      vacunadorId: map['vacunadorId'] ?? '',
      sincronizado: map['sincronizado'] ?? false,
    );
  }
}