import 'dart:io';

import 'package:flutter/material.dart';
import 'models/reporte.dart';
import 'problema.dart';

class ListaProblemasPage extends StatelessWidget {
  final List<Reporte> reportes;
  const ListaProblemasPage({super.key, this.reportes = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text(
          'Problemas Propuestos',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.normal),
        ),
      ),
      body: reportes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.report_problem_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No hay reportes aún', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Pulsa + para agregar un nuevo reporte', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.separated(
              // dejar espacio abajo para que la barra inferior no tape el último elemento
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: reportes.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final r = reportes[index];
                return ListTile(
                  leading: r.imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(r.imagePath), width: 56, height: 56, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.report_problem_outlined),
                  title: Text(r.titulo),
                  subtitle: Text(r.descripcion),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProblemaPage(reporte: r),
                    ));
                  },
                );
              },
            ),
    );
  }
}
 
