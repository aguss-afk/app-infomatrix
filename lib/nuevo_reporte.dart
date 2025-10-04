import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'map_select_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _isSubmitting = false;
  LatLng? _selectedLocation;
  String? _selectedAddress;

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

  Future<void> _guardar() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor adjunta una foto antes de guardar')),
      );
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una ubicación antes de guardar')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        await supabase.auth.signInAnonymously();
      }
      final user = supabase.auth.currentUser!;
      final userId = user.id;

    final bytes = await _pickedImage!.readAsBytes();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final basename = _pickedImage!.path.split(RegExp(r'[\\/]+')).last;
    final fileName = '${timestamp}_$basename';

    // Upload bytes to Supabase Storage bucket 'reportes'
    await supabase.storage.from('reportes').uploadBinary(fileName, bytes);

      // Construct public URL for the uploaded object. Replace with your project URL if different.
      final supabaseUrl = 'https://ztjotyybcvnxveohnewv.supabase.co';
      final publicUrl = '$supabaseUrl/storage/v1/object/public/reportes/$fileName';

      // Insert row into 'reportes' table
      await supabase.from('reportes').insert({
        'titulo': _selectedTitulo ?? _titulos.first,
        'direccion': _selectedAddress ?? _direccionCtrl.text,
        'descripcion': _descripcionCtrl.text,
        'image_url': publicUrl,
        'user_id': userId,
        'latitude': _selectedLocation?.latitude,
        'longitude': _selectedLocation?.longitude,
        'created_at': DateTime.now().toIso8601String(),
      }).select();


      // If we reach here without throwing, treat as success.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte enviado')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

                    // Dirección: botón que abre el mapa en lugar de TextField
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.map_outlined),
              label: Text(_selectedLocation == null
                ? 'Seleccionar ubicación en el mapa'
                : 'Ubicación: ' + (_selectedAddress == null ? '${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}' : (_selectedAddress!.length > 20 ? _selectedAddress!.substring(0, 20) + '...' : _selectedAddress!))),
                            onPressed: () async {
                              final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapSelectPage()));
                              if (res is Map<String, dynamic>) {
                                final lat = (res['lat'] as num).toDouble();
                                final lng = (res['lng'] as num).toDouble();
                                String? name;
                                try {
                                  final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng');
                                  final r = await http.get(url, headers: {'User-Agent': 'app2/1.0'});
                                  if (r.statusCode == 200) {
                                    final data = json.decode(r.body) as Map<String, dynamic>;
                                    name = data['display_name'] as String?;
                                  }
                                } catch (e) {
                                  debugPrint('Reverse geocode failed: $e');
                                }

                                setState(() {
                                  _selectedLocation = LatLng(lat, lng);
                                  _selectedAddress = name;
                                });
                              }
                            },
                          ),
                        ),
                        if (_selectedLocation != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _selectedLocation = null;
                              _selectedAddress = null;
                            }),
                          ),
                        ],
                      ],
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


            // Botón fijo en la parte inferior
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _guardar,
                icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Text(_isSubmitting ? 'Enviando...' : 'Enviar reporte'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
