import 'package:flutter/material.dart';

class DarkDialogField extends StatefulWidget {
  final String tytul;
  final Color tytulKolor;
  final String hintText;
  final String poczatkowaWartosc;
  final String labelPrzycisku;
  final Future<void> Function(String) onSubmit;

  const DarkDialogField({
    super.key,
    required this.tytul,
    required this.tytulKolor,
    required this.hintText,
    this.poczatkowaWartosc = '',
    required this.labelPrzycisku,
    required this.onSubmit,
  });

  @override
  State<DarkDialogField> createState() => _DarkDialogFieldState();
}

class _DarkDialogFieldState extends State<DarkDialogField> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.poczatkowaWartosc);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final wartosc = _ctrl.text.trim();
    if (wartosc.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onSubmit(wartosc);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        widget.tytul,
        style: TextStyle(color: widget.tytulKolor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            enabled: !_loading,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey[600]),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.tealAccent),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_loading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: Text(
            widget.labelPrzycisku,
            style: const TextStyle(color: Colors.tealAccent),
          ),
        ),
      ],
    );
  }
}
