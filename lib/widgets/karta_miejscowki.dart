import 'package:flutter/material.dart';
import '../models/miejscowka.dart';

class KartaMiejscowki extends StatelessWidget {
  final Miejscowka miejscowka;

  const KartaMiejscowki({super.key, required this.miejscowka});

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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                if (miejscowka.kategoria?.nazwa != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      miejscowka.kategoria!.nazwa,
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (miejscowka.opis.isNotEmpty)
              Text(
                miejscowka.opis,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
              ),
            const SizedBox(height: 10),
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
