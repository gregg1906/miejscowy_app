import 'package:flutter/material.dart';
import '../models/kategoria.dart';

class KategoriaDropdown extends StatelessWidget {
  final List<Kategoria> kategorie;
  final String? wybranaKategoriaId;
  final ValueChanged<String?> onChanged;
  final Future<Kategoria> Function(String nazwa) onDodajKategorie;
  final ValueChanged<Kategoria> onKategoriaAdded;

  const KategoriaDropdown({
    super.key,
    required this.kategorie,
    required this.wybranaKategoriaId,
    required this.onChanged,
    required this.onDodajKategorie,
    required this.onKategoriaAdded,
  });

  void _pokazDialog(BuildContext context) {
    final nazwaCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Nowa kategoria',
            style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nazwaCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                enabled: !loading,
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
              ),
              if (loading) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () async {
                      final nazwa = nazwaCtrl.text.trim();
                      if (nazwa.isEmpty) return;
                      setDialogState(() => loading = true);
                      try {
                        final nowaKat = await onDodajKategorie(nazwa);
                        onKategoriaAdded(nowaKat);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.redAccent),
                          );
                          setDialogState(() => loading = false);
                        }
                      }
                    },
              child: const Text('Zapisz', style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        ),
      ),
    ).then((_) => nazwaCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey(wybranaKategoriaId),
            initialValue: wybranaKategoriaId,
            decoration: InputDecoration(
              labelText: 'Kategoria',
              labelStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.category, color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
              ),
            ),
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            hint: Text('Wybierz kategorię', style: TextStyle(color: Colors.grey[600])),
            items: kategorie
                .map((kat) => DropdownMenuItem<String>(value: kat.id, child: Text(kat.nazwa)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.tealAccent, size: 30),
          tooltip: 'Dodaj nową kategorię',
          onPressed: () => _pokazDialog(context),
        ),
      ],
    );
  }
}
