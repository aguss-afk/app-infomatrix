import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapSelectPage extends StatefulWidget {
  final LatLng? initialLocation;
  const MapSelectPage({super.key, this.initialLocation});

  @override
  State<MapSelectPage> createState() => _MapSelectPageState();
}

class _MapSelectPageState extends State<MapSelectPage> {
  late final MapController _mapController;
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _picked = widget.initialLocation;
    // try to center on user location if available
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      // if the user hasn't picked a point and there's no initialLocation, center map here
      if (_picked == null && widget.initialLocation == null) {
        _mapController.move(userLatLng, 13.0);
      }
    } catch (e) {
      debugPrint('Could not get user location: $e');
    }
  }

  void _onTap(TapPosition _, LatLng latlng) {
    setState(() => _picked = latlng);
    _mapController.move(latlng, _mapController.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ?? widget.initialLocation ?? LatLng(-34.6037, -58.3816);
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicación')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: center,
          zoom: 13,
          onTap: _onTap,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app2',
          ),
          if (_picked != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _picked!,
                  width: 48,
                  height: 48,
                  builder: (ctx) => const Icon(Icons.location_on, color: Colors.red, size: 36),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Confirmar ubicación'),
                onPressed: _picked == null
                    ? null
                    : () {
                        Navigator.of(context).pop({'lat': _picked!.latitude, 'lng': _picked!.longitude});
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
