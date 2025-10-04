import 'dart:convert';

class Reporte {
  final String titulo;
  final String direccion;
  final String descripcion;
  final String imagePath; // local path (optional)
  final String? imageUrl; // remote URL (optional)

  Reporte({
    required this.titulo,
    required this.direccion,
    required this.descripcion,
    this.imagePath = '',
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'direccion': direccion,
        'descripcion': descripcion,
    'imagePath': imagePath,
    'imageUrl': imageUrl,
      };

  factory Reporte.fromJson(Map<String, dynamic> json) => Reporte(
        titulo: json['titulo'] as String,
        direccion: json['direccion'] as String,
        descripcion: json['descripcion'] as String,
        imagePath: json['imagePath'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
      );

  factory Reporte.fromSupabase(Map<String, dynamic> row) => Reporte(
        titulo: row['titulo'] as String? ?? '',
        direccion: row['direccion'] as String? ?? '',
        descripcion: row['descripcion'] as String? ?? '',
        imageUrl: row['image_url'] as String?,
      );

  String encode() => json.encode(toJson());

  static Reporte decode(String s) => Reporte.fromJson(json.decode(s));
}
