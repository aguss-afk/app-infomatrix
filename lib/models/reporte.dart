import 'dart:convert';

class Reporte {
  final String titulo;
  final String direccion;
  final String descripcion;
  final String imagePath;

  Reporte({
    required this.titulo,
    required this.direccion,
    required this.descripcion,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'direccion': direccion,
        'descripcion': descripcion,
        'imagePath': imagePath,
      };

  factory Reporte.fromJson(Map<String, dynamic> json) => Reporte(
        titulo: json['titulo'] as String,
        direccion: json['direccion'] as String,
        descripcion: json['descripcion'] as String,
        imagePath: json['imagePath'] as String,
      );

  String encode() => json.encode(toJson());

  static Reporte decode(String s) => Reporte.fromJson(json.decode(s));
}
