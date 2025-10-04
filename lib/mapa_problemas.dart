import 'package:flutter/material.dart';

class MapaProblemasPage extends StatelessWidget {
  const MapaProblemasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text(
          'Mapa de problemas',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.normal),
        ),
      ),
      body: const Center(
        child: Text('Placeholder para mapa (aquí irá un mapa o un widget de mapas).'),
      ),
    );
  }
}
