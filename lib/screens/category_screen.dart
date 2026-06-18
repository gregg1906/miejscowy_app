import 'package:flutter/material.dart';
import '../models/kategoria.dart';
import '../services/supabase_service.dart';

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

  // ── Dialog: Dodaj nową kategorię ─────────────────────────────────────────────
  void _pokazDialogDodawania() {
    final ctrl = TextEditingController();
    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Nowa kategoria',
                style: TextStyle(
                    color: Colors.tealAccent, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nazwa kategorii',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.tealAccent),
                      ),
                    ),
                    enabled: !dialogLoading,
                  ),
                  if (dialogLoading) ...[
                    const SizedBox(height: 20),
                    const Center(
                      child: CircularProgressIndicator(color: Colors.tealAccent),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final nazwa = ctrl.text.trim();
                          if (nazwa.isEmpty) return;
                          setDialogState(() => dialogLoading = true);
                          try {
                            final nowaKat =
                                await _supabaseService.dodajKategorie(nazwa);
                            if (mounted) {
                              setState(() => _kategorie.add(nowaKat));
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text('Błąd: $e'),
                                backgroundColor: Colors.redAccent,
                              ));
                              setDialogState(() => dialogLoading = false);
                            }
                          }
                        },
                  child: const Text('Dodaj',
                      style: TextStyle(color: Colors.tealAccent)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => ctrl.dispose());
  }

  // ── Dialog: Edytuj kategorię ─────────────────────────────────────────────────
  void _pokazDialogEdycji(Kategoria kat) {
    final ctrl = TextEditingController(text: kat.nazwa);
    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Edytuj kategorię',
                style: TextStyle(
                    color: Colors.tealAccent, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nowa nazwa',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.tealAccent),
                      ),
                    ),
                    enabled: !dialogLoading,
                  ),
                  if (dialogLoading) ...[
                    const SizedBox(height: 20),
                    const Center(
                      child: CircularProgressIndicator(color: Colors.tealAccent),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final nowaNazwa = ctrl.text.trim();
                          if (nowaNazwa.isEmpty) return;
                          setDialogState(() => dialogLoading = true);
                          try {
                            await _supabaseService.edytujKategorie(
                                kat.id, nowaNazwa);
                            if (mounted) {
                              setState(() {
                                final idx =
                                    _kategorie.indexWhere((k) => k.id == kat.id);
                                if (idx != -1) {
                                  _kategorie[idx] =
                                      Kategoria(id: kat.id, nazwa: nowaNazwa);
                                }
                              });
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text('Błąd: $e'),
                                backgroundColor: Colors.redAccent,
                              ));
                              setDialogState(() => dialogLoading = false);
                            }
                          }
                        },
                  child: const Text('Zapisz',
                      style: TextStyle(color: Colors.tealAccent)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => ctrl.dispose());
  }

  // ── Dialog: Usuń kategorię ───────────────────────────────────────────────────
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
                if (mounted) {
                  setState(() => _kategorie.removeWhere((k) => k.id == kat.id));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Błąd usuwania: $e'),
                    backgroundColor: Colors.redAccent,
                  ));
                }
              }
            },
            child: const Text(
              'Tak, usuń',
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
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
          style:
              TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent))
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: _kategorie.length,
                  itemBuilder: (context, index) {
                    final kat = _kategorie[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey[850]!, width: 1),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.label,
                              color: Colors.tealAccent, size: 20),
                        ),
                        title: Text(
                          kat.nazwa,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.tealAccent, size: 22),
                              tooltip: 'Edytuj nazwę',
                              onPressed: () => _pokazDialogEdycji(kat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent, size: 22),
                              tooltip: 'Usuń kategorię',
                              onPressed: () => _pokazDialogUsuwania(kat),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
