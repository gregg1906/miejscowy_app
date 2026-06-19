import 'package:flutter/material.dart';
import '../models/kategoria.dart';
import '../models/miejscowka.dart';
import '../services/supabase_service.dart';
import '../widgets/animowana_karta.dart';
import '../widgets/karta_miejscowki.dart';
import 'add_screen.dart';
import 'category_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Miejscowka> wszystkieMiejscowki = [];
  List<Kategoria> kategorie = [];
  bool _isLoading = true;
  String wybranyFiltr = 'Wszystkie';

  @override
  void initState() {
    super.initState();
    _loadDane();
  }

  Future<void> _loadDane() async {
    final wyniki = await Future.wait([
      _supabaseService.pobierzMiejscowki(),
      _supabaseService.pobierzKategorie(),
    ]);
    if (mounted) {
      setState(() {
        wszystkieMiejscowki = wyniki[0] as List<Miejscowka>;
        kategorie = wyniki[1] as List<Kategoria>;
        _isLoading = false;
      });
    }
  }

  List<Miejscowka> get _przefiltrowane {
    if (wybranyFiltr == 'Wszystkie') return wszystkieMiejscowki;
    return wszystkieMiejscowki.where((m) => m.kategoria?.nazwa == wybranyFiltr).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Miejscówki',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.tealAccent, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.label, color: Colors.tealAccent),
            tooltip: 'Zarządzaj kategoriami',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen()));
              _loadDane();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[850]),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kategorie.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filtr = index == 0 ? 'Wszystkie' : kategorie[index - 1].nazwa;
                final wybrany = filtr == wybranyFiltr;
                return ChoiceChip(
                  label: Text(filtr),
                  selected: wybrany,
                  onSelected: (_) => setState(() => wybranyFiltr = filtr),
                  selectedColor: Colors.tealAccent,
                  backgroundColor: const Color(0xFF2A2A2A),
                  labelStyle: TextStyle(
                    color: wybrany ? Colors.black : Colors.grey[300],
                    fontWeight: wybrany ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: wybrany ? Colors.tealAccent : Colors.grey[800]!, width: 1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : _przefiltrowane.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[700]),
                            const SizedBox(height: 12),
                            Text(
                              'Brak wyników dla "$wybranyFiltr"',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _przefiltrowane.length,
                        itemBuilder: (context, index) {
                          final miejscowka = _przefiltrowane[index];
                          return AnimowanaKarta(
                            key: ValueKey('${miejscowka.id}_$wybranyFiltr'),
                            index: index,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddScreen(miejscowkaDoEdycji: miejscowka)),
                                );
                                _loadDane();
                              },
                              child: KartaMiejscowki(miejscowka: miejscowka),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
