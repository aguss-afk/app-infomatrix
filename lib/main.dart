import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lista_problemas.dart';
import 'nuevo_reporte.dart';
import 'mapa_problemas.dart';
import 'models/reporte.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Si usas FlutterFire CLI genera firebase_options.dart y pásalo a initializeApp
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const MainHome(),
    );
  }
}

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _currentIndex = 0; // 0 = lista (inicio), 1 = FAB, 2 = ubicación
  final List<Reporte> _reportes = [];

  List<Widget> get _pages => [
        // Página de lista (reportes cargados)
        ListaProblemasPage(reportes: _reportes),
        // Página central (no usada porque abrimos pantalla nueva con Navigator)
        const Center(child: Text("Página central (+)")),
        // Página ubicación (mapa) - se mantiene dentro del Scaffold para que la barra siga visible
        const MapaProblemasPage(),
      ];

  static const _kReportesKey = 'reportes_list';

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  Future<void> _loadReportes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kReportesKey) ?? [];
    setState(() {
      _reportes.clear();
      _reportes.addAll(raw.map((s) => Reporte.decode(s)));
    });
  }

  Future<void> _saveReportes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _reportes.map((r) => r.encode()).toList();
    await prefs.setStringList(_kReportesKey, raw);
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openNuevoReporte() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const NuevoReportePage(),
    ));

    if (result == null || result is! Map) return;

    final nuevo = Reporte(
      titulo: result['titulo'] as String? ?? 'Sin título',
      direccion: result['direccion'] as String? ?? '',
      descripcion: result['descripcion'] as String? ?? '',
      imagePath: result['imagePath'] as String? ?? '',
    );

    setState(() {
      _reportes.insert(0, nuevo);
    });
    await _saveReportes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Transform.translate(
        offset: const Offset(0, 10),
        child: SizedBox(
          width: 72,
          height: 72,
            child: FloatingActionButton(
            onPressed: _openNuevoReporte,
            elevation: 6,
            shape: const CircleBorder(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add, size: 40),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
            boxShadow: [
              // sombra difusa más pronunciada
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              // sombra sutil cercana
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _changePage(0),
                icon: const Icon(Icons.list_alt),
                iconSize: 30,
                color: _currentIndex == 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 72),
              IconButton(
                onPressed: () => _changePage(2),
                icon: const Icon(Icons.location_on_sharp),
                iconSize: 30,
                color: _currentIndex == 2
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
