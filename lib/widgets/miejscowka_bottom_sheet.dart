import 'package:flutter/material.dart';
import '../models/miejscowka.dart';
import '../screens/add_screen.dart';

class MiejscowkaBottomSheet extends StatelessWidget {
  final Miejscowka miejscowka;
  final VoidCallback onDataChanged;
  final Future<void> Function(String id) onDelete;

  const MiejscowkaBottomSheet({
    super.key,
    required this.miejscowka,
    required this.onDataChanged,
    required this.onDelete,
  });

  static void show(
    BuildContext context, {
    required Miejscowka miejscowka,
    required VoidCallback onDataChanged,
    required Future<void> Function(String id) onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MiejscowkaBottomSheet(
        miejscowka: miejscowka,
        onDataChanged: onDataChanged,
        onDelete: onDelete,
      ),
    );
  }

  void _pokazZdjeciePelnyEkran(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pokazDialogUsuwania(BuildContext sheetCtx) {
    showDialog(
      context: sheetCtx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Usuń miejsce',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Czy usunąć "${miejscowka.nazwa}"? Tej operacji nie można cofnąć.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              Navigator.pop(sheetCtx);
              try {
                await onDelete(miejscowka.id);
                onDataChanged();
              } catch (e) {
                if (sheetCtx.mounted) {
                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                    SnackBar(content: Text('Błąd usuwania: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text(
              'Tak, usuń',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            miejscowka.nazwa,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          if (miejscowka.kategoria?.nazwa != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                miejscowka.kategoria!.nazwa,
                style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 8),
          if (miejscowka.opis.isNotEmpty) ...[
            Text(
              miejscowka.opis,
              style: TextStyle(fontSize: 15, color: Colors.grey[300], height: 1.4),
            ),
            const SizedBox(height: 8),
          ],
          if (miejscowka.godzinyOtwarcia.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[400], size: 18),
                const SizedBox(width: 8),
                Text(
                  miejscowka.godzinyOtwarcia,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (miejscowka.zdjeciaUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: miejscowka.zdjeciaUrl.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _pokazZdjeciePelnyEkran(context, miejscowka.zdjeciaUrl[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        miejscowka.zdjeciaUrl[index],
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) => Container(
                          width: 160,
                          color: Colors.grey[800],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Zamknij'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddScreen(miejscowkaDoEdycji: miejscowka)),
                  );
                  onDataChanged();
                },
                icon: const Icon(Icons.edit, size: 18, color: Colors.black),
                label: const Text('Edytuj', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              TextButton.icon(
                onPressed: () => _pokazDialogUsuwania(context),
                icon: const Icon(Icons.delete_forever, size: 18),
                label: const Text('Usuń'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
