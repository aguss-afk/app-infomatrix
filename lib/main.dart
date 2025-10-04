import 'package:flutter/material.dart';
import 'lista_problemas.dart';
import 'nuevo_reporte.dart';
import 'mapa_problemas.dart';
import 'models/reporte.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ztjotyybcvnxveohnewv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0am90eXliY3ZueHZlb2huZXd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1ODIyOTMsImV4cCI6MjA3NTE1ODI5M30.s0kesjB8FgNnnw1BajM-xuIC2kCtsn4Mw1Sq3pq6ARQ',
  );
  // Ensure there's a single anonymous user for the whole app so uploads and streams use the same user_id
  try {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously();
      debugPrint('Signed in anonymously at startup. userId=${supabase.auth.currentUser?.id}');
    } else {
      debugPrint('Supabase already has user: ${supabase.auth.currentUser?.id}');
    }
  } catch (e) {
    debugPrint('Anonymous sign-in failed at startup: $e');
  }
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
        const ListaProblemasPage(),
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
