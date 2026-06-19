import 'package:flutter/material.dart';
import '../models/kategoria.dart';

class KartaKategorii extends StatelessWidget {
  final Kategoria kategoria;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const KartaKategorii({
    super.key,
    required this.kategoria,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[850]!, width: 1),
      ),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.tealAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.label, color: Colors.tealAccent, size: 20),
        ),
        title: Text(
          kategoria.nazwa,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.tealAccent, size: 22),
              tooltip: 'Edytuj nazwę',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
              tooltip: 'Usuń kategorię',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
