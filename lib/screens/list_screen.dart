import 'package:flutter/material.dart';
import '../models/kategoria.dart';
import '../models/miejscowka.dart';
import '../services/supabase_service.dart';
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
    return wszystkieMiejscowki
        .where((m) => m.kategoria?.nazwa == wybranyFiltr)
        .toList();
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
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.tealAccent,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.label, color: Colors.tealAccent),
            tooltip: 'Zarządzaj kategoriami',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CategoryScreen()),
              );
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
          // ── Paski filtrów (ChoiceChip) — dynamiczne z bazy ────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // 'Wszystkie' + każda kategoria z bazy
              itemCount: kategorie.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filtr =
                    index == 0 ? 'Wszystkie' : kategorie[index - 1].nazwa;
                final wybrany = filtr == wybranyFiltr;
                return ChoiceChip(
                  label: Text(filtr),
                  selected: wybrany,
                  onSelected: (_) {
                    setState(() {
                      wybranyFiltr = filtr;
                    });
                  },
                  selectedColor: Colors.tealAccent,
                  backgroundColor: const Color(0xFF2A2A2A),
                  labelStyle: TextStyle(
                    color: wybrany ? Colors.black : Colors.grey[300],
                    fontWeight:
                        wybrany ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          wybrany ? Colors.tealAccent : Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Lista miejsc ───────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Colors.tealAccent),
                  )
                : _przefiltrowane.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 60, color: Colors.grey[700]),
                            const SizedBox(height: 12),
                            Text(
                              'Brak wyników dla "$wybranyFiltr"',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: _przefiltrowane.length,
                        itemBuilder: (context, index) {
                          final miejscowka = _przefiltrowane[index];
                          return _AnimowanaKarta(
                            key: ValueKey(
                                '${miejscowka.id}_$wybranyFiltr'),
                            index: index,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddScreen(
                                        miejscowkaDoEdycji: miejscowka),
                                  ),
                                );
                                _loadDane();
                              },
                              child: _KartaMiejscowki(miejscowka: miejscowka),
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

// Animowany wrapper z TweenAnimationBuilder
class _AnimowanaKarta extends StatelessWidget {
  const _AnimowanaKarta({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Opóźnienie na podstawie indeksu — każda karta pojawia się po kolei
    final delay = Duration(milliseconds: 60 * index);

    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: FutureBuilder(
        future: Future.delayed(delay),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          return child;
        },
      ),
    );
  }
}

//Karta miejscówy
class _KartaMiejscowki extends StatelessWidget {
  const _KartaMiejscowki({required this.miejscowka});
  final Miejscowka miejscowka;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[850]!, width: 1),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    miejscowka.nazwa,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (miejscowka.kategoria?.nazwa != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      miejscowka.kategoria!.nazwa,
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Opis
            if (miejscowka.opis.isNotEmpty)
              Text(
                miejscowka.opis,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 10),

            // Godziny otwarcia
            if (miejscowka.godzinyOtwarcia.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600], size: 15),
                  const SizedBox(width: 6),
                  Text(
                    miejscowka.godzinyOtwarcia,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
