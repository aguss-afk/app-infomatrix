import 'dart:io';

import 'package:flutter/material.dart';
import 'models/reporte.dart';

class ProblemaPage extends StatelessWidget {
  final Reporte reporte;
  const ProblemaPage({super.key, required this.reporte});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del problema')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((reporte.imageUrl ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  reporte.imageUrl!,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else if (reporte.imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(reporte.imagePath),
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Text(reporte.titulo, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(reporte.direccion, style: const TextStyle(color: Color.fromARGB(255, 87, 87, 87), fontSize:  16))),
              ],
            ),
            const SizedBox(height: 12),
            Text(reporte.descripcion, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
