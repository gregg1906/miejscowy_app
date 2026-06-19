import 'package:flutter/material.dart';

class CzasOtwarciaRow extends StatelessWidget {
  final TimeOfDay? czasOtwarcia;
  final TimeOfDay? czasZamkniecia;
  final ValueChanged<TimeOfDay> onOtwarcieChanged;
  final ValueChanged<TimeOfDay> onZamkniecieChanged;

  const CzasOtwarciaRow({
    super.key,
    required this.czasOtwarcia,
    required this.czasZamkniecia,
    required this.onOtwarcieChanged,
    required this.onZamkniecieChanged,
  });

  Future<void> _wybierzCzas(
    BuildContext context,
    TimeOfDay poczatkowy,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: poczatkowy,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  String _formatujCzas(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _wybierzCzas(
              context,
              czasOtwarcia ?? const TimeOfDay(hour: 9, minute: 0),
              onOtwarcieChanged,
            ),
            icon: const Icon(Icons.access_time, color: Colors.tealAccent, size: 20),
            label: Text(
              czasOtwarcia != null ? 'Od: ${_formatujCzas(czasOtwarcia!)}' : 'Otwarcie',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[800]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _wybierzCzas(
              context,
              czasZamkniecia ?? const TimeOfDay(hour: 18, minute: 0),
              onZamkniecieChanged,
            ),
            icon: const Icon(Icons.access_time_filled, color: Colors.tealAccent, size: 20),
            label: Text(
              czasZamkniecia != null ? 'Do: ${_formatujCzas(czasZamkniecia!)}' : 'Zamknięcie',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[800]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
