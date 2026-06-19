import 'package:flutter/material.dart';
import '../models/kategoria.dart';
import '../services/supabase_service.dart';
import '../widgets/karta_kategorii.dart';
import '../widgets/dark_dialog_field.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Kategoria> _kategorie = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKategorie();
  }

  Future<void> _loadKategorie() async {
    final wynik = await _supabaseService.pobierzKategorie();
    if (mounted) {
      setState(() {
        _kategorie = wynik;
        _isLoading = false;
      });
    }
  }

  void _pokazDialogDodawania() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DarkDialogField(
        tytul: 'Nowa kategoria',
        tytulKolor: Colors.tealAccent,
        hintText: 'Nazwa kategorii',
        labelPrzycisku: 'Dodaj',
        onSubmit: (nazwa) async {
          final nowaKat = await _supabaseService.dodajKategorie(nazwa);
          if (mounted) setState(() => _kategorie.add(nowaKat));
        },
      ),
    );
  }

  void _pokazDialogEdycji(Kategoria kat) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DarkDialogField(
        tytul: 'Edytuj kategorię',
        tytulKolor: Colors.tealAccent,
        hintText: 'Nowa nazwa',
        poczatkowaWartosc: kat.nazwa,
        labelPrzycisku: 'Zapisz',
        onSubmit: (nowaNazwa) async {
          await _supabaseService.edytujKategorie(kat.id, nowaNazwa);
          if (mounted) {
            setState(() {
              final idx = _kategorie.indexWhere((k) => k.id == kat.id);
              if (idx != -1) _kategorie[idx] = Kategoria(id: kat.id, nazwa: nowaNazwa);
            });
          }
        },
      ),
    );
  }

  void _pokazDialogUsuwania(Kategoria kat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Usuń kategorię',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Usunąć kategorię "${kat.nazwa}"? Tej operacji nie można cofnąć.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabaseService.usunKategorie(kat.id);
                if (mounted) setState(() => _kategorie.removeWhere((k) => k.id == kat.id));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd usuwania: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Tak, usuń', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Zarządzaj Kategoriami',
          style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.tealAccent),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[850]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pokazDialogDodawania,
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        tooltip: 'Dodaj kategorię',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : _kategorie.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_off, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Brak kategorii.\nDodaj pierwszą klikając +',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _kategorie.length,
                  itemBuilder: (context, index) {
                    final kat = _kategorie[index];
                    return KartaKategorii(
                      kategoria: kat,
                      onEdit: () => _pokazDialogEdycji(kat),
                      onDelete: () => _pokazDialogUsuwania(kat),
                    );
                  },
                ),
    );
  }
}
