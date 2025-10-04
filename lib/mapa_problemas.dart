import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'problema.dart';
import 'models/reporte.dart';

class MapaProblemasPage extends StatefulWidget {
  const MapaProblemasPage({super.key});

  @override
  State<MapaProblemasPage> createState() => _MapaProblemasPageState();
}

class _MapaProblemasPageState extends State<MapaProblemasPage> {
  List<Map<String, dynamic>> _reportes = [];
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  String? _error;
  bool _loading = true;
  bool _localizando = true;
  Position? _userPosition;
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _subscribeToReportes();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Los servicios de ubicación están desactivados. Por favor actívalos.'),
      ));
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Los permisos de ubicación fueron denegados'),
        ));
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos.'
        ),
      ));
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _localizando = true);

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() => _localizando = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      if (!mounted) return;
      
      setState(() {
        _userPosition = position;
        _localizando = false;
      });
      
      // Center map on user's location
      mapController.move(
        LatLng(position.latitude, position.longitude),
        13.0
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      setState(() => _localizando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener la ubicación'))
      );
    }
  }

  Future<void> _subscribeToReportes() async {
    _sub?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final stream = supabase
          .from('reportes')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);

      _sub = stream.listen(
        (data) {
          if (!mounted) return;
          setState(() {
            _reportes = data;
            _loading = false;
          });
        },
        onError: (error) {
          debugPrint('Error en stream de reportes: $error');
          if (!mounted) return;
          setState(() {
            _error = error.toString();
            _loading = false;
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : LatLng(-34.6037, -58.3816);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text(
          'Mapa de problemas',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.normal),
        ),
        actions: [
          if (_error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _subscribeToReportes,
              tooltip: 'Reintentar',
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _localizando ? null : () {
              if (_userPosition != null) {
                mapController.move(
                  LatLng(_userPosition!.latitude, _userPosition!.longitude),
                  15.0
                );
              } else {
                _getCurrentLocation();
              }
            },
            tooltip: 'Mi ubicación',
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar reportes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _subscribeToReportes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: currentPosition,
                    zoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'app2',
                    ),
                    // Capa de marcadores de reportes
                    MarkerLayer(
                      markers: _reportes.map((row) {
                        final reporte = Reporte.fromSupabase(row);
                        if (row['latitude'] == null || row['longitude'] == null) return null;
                        
                        return Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(
                            (row['latitude'] as num).toDouble(),
                            (row['longitude'] as num).toDouble(),
                          ),
                          builder: (context) => GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reporte.titulo,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.arrow_forward),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ProblemaPage(reporte: reporte),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(reporte.direccion, style: TextStyle(color: const Color.fromARGB(255, 90, 90, 90)),)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        reporte.descripcion,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      }).whereType<Marker>().toList(),
                    ),
                    // Marcador de ubicación del usuario
                    if (_userPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                            width: 30,
                            height: 30,
                            builder: (context) => Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_loading || _localizando)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Card(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(_localizando ? 'Obteniendo ubicación...' : 'Cargando reportes...'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
