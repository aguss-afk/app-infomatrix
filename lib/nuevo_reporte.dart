import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NuevoReportePage extends StatefulWidget {
  const NuevoReportePage({super.key});

  @override
  State<NuevoReportePage> createState() => _NuevoReportePageState();
}

class _NuevoReportePageState extends State<NuevoReportePage> {
  final List<String> _titulos = [
    'Bache',
    'Luminaria apagada',
    'Basura acumulada',
    'Semáforo',
  ];

  String? _selectedTitulo;
  final TextEditingController _direccionCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    setState(() {
      _pickedImage = File(picked.path);
    });
  }

  @override
  void dispose() {
    _direccionCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor adjunta una foto antes de guardar')),
      );
      return;
    }

    final data = {
      'titulo': _selectedTitulo ?? _titulos.first,
      'direccion': _direccionCtrl.text,
      'descripcion': _descripcionCtrl.text,
      'imagePath': _pickedImage!.path,
    };
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Complete los datos del reporte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dropdown para título
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTitulo,
                      decoration: const InputDecoration(labelText: 'Título'),
                      items: _titulos
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTitulo = v),
                    ),
                    const SizedBox(height: 12),

                    // Dirección (temporalmente texto)
                    TextField(
                      controller: _direccionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección (se reemplazará por mapa)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Descripción
                    TextField(
                      controller: _descripcionCtrl,
                      decoration: const InputDecoration(labelText: 'Descripción del problema'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),

                    // Imagen (preview + botón)
                    _pickedImage == null
                        ? GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.camera_alt_outlined, size: 32, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Adjuntar foto (requerido)', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _pickedImage!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: InkWell(
                                  onTap: () => setState(() => _pickedImage = null),
                                  child: const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              )
                            ],
                          ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Botón fijo en la parte inferior
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('Guardar reporte'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
