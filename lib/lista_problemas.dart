import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/reporte.dart';
import 'problema.dart';

class ListaProblemasPage extends StatefulWidget {
  const ListaProblemasPage({super.key});

  @override
  State<ListaProblemasPage> createState() => _ListaProblemasPageState();
}

class _ListaProblemasPageState extends State<ListaProblemasPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _ensureUser();
  }

  Future<void> _ensureUser() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      try {
        await supabase.auth.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous sign-in failed: $e');
      }
    }
    setState(() => _userId = supabase.auth.currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text(
          'Problemas Propuestos',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.normal),
        ),
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('reportes')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', _userId!)
                  .order('created_at', ascending: false),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                final rows = snap.data ?? [];
                if (rows.isEmpty) {
                  return Center(
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
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final r = Reporte.fromSupabase(row);

                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProblemaPage(reporte: r))),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // image area (smaller)
                            Container(
                              height: 110,
                              color: Colors.grey.shade200,
                              child: r.imageUrl != null && r.imageUrl!.isNotEmpty
                                  ? Image.network(r.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                                  : r.imagePath.isNotEmpty
                                      ? Image.file(File(r.imagePath), fit: BoxFit.cover, width: double.infinity)
                                      : const Center(child: Icon(Icons.report_problem_outlined, size: 40, color: Colors.grey)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(r.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(r.direccion, style: const TextStyle(fontSize: 13, color: Color.fromARGB(221, 80, 80, 80)))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(r.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
