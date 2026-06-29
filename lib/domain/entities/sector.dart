class Sector {
  final String id;
  final String nombre;
  final String ciudad;
  final String descripcion;
  final String? coordinadorId;

  const Sector({
    required this.id,
    required this.nombre,
    required this.ciudad,
    this.descripcion = '',
    this.coordinadorId,
  });

  factory Sector.fromMap(String id, Map<String, dynamic> map) {
    return Sector(
      id: id,
      nombre: map['nombre'] ?? '',
      // compatibilidad con ambas estructuras
      ciudad: map['ciudad'] ?? map['parroquia'] ?? map['zona'] ?? '',
      descripcion: map['descripcion'] ?? map['zona'] ?? '',
      coordinadorId: map['coordinadorId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'ciudad': ciudad,
    'descripcion': descripcion,
    'coordinadorId': coordinadorId,
  };
}