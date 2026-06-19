import 'package:flutter/material.dart';
import '../models/kategoria.dart';

class MapaFilterBar extends StatelessWidget {
  final List<Kategoria> kategorie;
  final String wybranyFiltr;
  final ValueChanged<String> onFiltrChanged;

  const MapaFilterBar({
    super.key,
    required this.kategorie,
    required this.wybranyFiltr,
    required this.onFiltrChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                onSelected: (_) => onFiltrChanged(filtr),
                selectedColor: Colors.tealAccent,
                backgroundColor: const Color(0xFF2A2A2A),
                labelStyle: TextStyle(
                  color: wybrany ? Colors.black : Colors.grey[300],
                  fontWeight: wybrany ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: wybrany ? Colors.tealAccent : Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
