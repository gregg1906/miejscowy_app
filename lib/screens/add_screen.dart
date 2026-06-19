import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/kategoria.dart';
import '../models/miejscowka.dart';
import '../services/supabase_service.dart';
import '../widgets/lokalizacja_picker.dart';
import '../widgets/czas_otwarcia_row.dart';
import '../widgets/kategoria_dropdown.dart';

class AddScreen extends StatefulWidget {
  final Miejscowka? miejscowkaDoEdycji;

  const AddScreen({super.key, this.miejscowkaDoEdycji});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();

  final _nazwaCtrl = TextEditingController();
  final _opisCtrl = TextEditingController();
  final _zdjecieCtrl = TextEditingController();

  TimeOfDay? czasOtwarcia;
  TimeOfDay? czasZamkniecia;

  List<Kategoria> _kategorie = [];
  String? _wybranaKategoriaId;
  LatLng? wybranaLokalizacja;
  bool _isLoading = false;
  bool _loadingKategorie = true;

  @override
  void initState() {
    super.initState();
    _loadKategorie();

    if (widget.miejscowkaDoEdycji != null) {
      final m = widget.miejscowkaDoEdycji!;
      _nazwaCtrl.text = m.nazwa;
      _opisCtrl.text = m.opis;

      if (m.godzinyOtwarcia.isNotEmpty && m.godzinyOtwarcia != 'Brak danych') {
        try {
          final parts = m.godzinyOtwarcia.split(' - ');
          if (parts.length == 2) {
            final startParts = parts[0].split(':');
            final endParts = parts[1].split(':');
            if (startParts.length == 2 && endParts.length == 2) {
              czasOtwarcia = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
              czasZamkniecia = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
            }
          }
        } catch (e) {
          debugPrint('Błąd parsowania godzin: $e');
        }
      }

      if (m.zdjeciaUrl.isNotEmpty) {
        _zdjecieCtrl.text = m.zdjeciaUrl.join(', ');
      }
      _wybranaKategoriaId = m.kategoriaId ?? m.kategoria?.id;
      wybranaLokalizacja = LatLng(m.szerokoscGeo, m.dlugoscGeo);
    }
  }

  @override
  void dispose() {
    _nazwaCtrl.dispose();
    _opisCtrl.dispose();
    _zdjecieCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategorie() async {
    final wynik = await _supabaseService.pobierzKategorie();
    if (mounted) {
      setState(() {
        _kategorie = wynik;
        _loadingKategorie = false;
      });
    }
  }

  Future<void> _zapisz() async {
    if (!_formKey.currentState!.validate()) return;

    if (wybranaLokalizacja == null) {
      _pokazSnackBar('Wskaż miejsce na mapie!', blad: true);
      return;
    }

    if (_wybranaKategoriaId == null) {
      _pokazSnackBar('Wybierz kategorię miejsca.', blad: true);
      return;
    }

    setState(() => _isLoading = true);

    String godziny;
    if (czasOtwarcia != null && czasZamkniecia != null) {
      final otw = '${czasOtwarcia!.hour.toString().padLeft(2, '0')}:${czasOtwarcia!.minute.toString().padLeft(2, '0')}';
      final zam = '${czasZamkniecia!.hour.toString().padLeft(2, '0')}:${czasZamkniecia!.minute.toString().padLeft(2, '0')}';
      godziny = '$otw - $zam';
    } else {
      godziny = 'Brak danych';
    }

    try {
      if (widget.miejscowkaDoEdycji != null) {
        final zdj = _zdjecieCtrl.text.trim();
        await _supabaseService.edytujMiejscowke(
          widget.miejscowkaDoEdycji!.id,
          {
            'nazwa': _nazwaCtrl.text.trim(),
            'opis': _opisCtrl.text.trim(),
            'szerokosc_geo': wybranaLokalizacja!.latitude,
            'dlugosc_geo': wybranaLokalizacja!.longitude,
            'godziny_otwarcia': godziny,
            'zdjecia_url': zdj.isNotEmpty ? zdj.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [],
            'kategoria_id': _wybranaKategoriaId!,
          },
        );
      } else {
        await _supabaseService.dodajMiejscowke(
          nazwa: _nazwaCtrl.text.trim(),
          opis: _opisCtrl.text.trim(),
          szerokoscGeo: wybranaLokalizacja!.latitude,
          dlugoscGeo: wybranaLokalizacja!.longitude,
          godzinyOtwarcia: godziny,
          zdjecieUrl: _zdjecieCtrl.text.trim(),
          kategoriaId: _wybranaKategoriaId!,
        );
      }

      if (mounted) {
        _pokazSnackBar(widget.miejscowkaDoEdycji != null
            ? 'Miejscówka zaktualizowana pomyślnie!'
            : 'Miejscówka dodana pomyślnie!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _pokazSnackBar('Błąd zapisu: $e', blad: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pokazSnackBar(String msg, {bool blad = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: blad ? Colors.redAccent : Colors.teal,
      ),
    );
  }

  void _pokazDialogUsuwania() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Usuń miejsce',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Czy na pewno chcesz usunąć to miejsce? Tej operacji nie można cofnąć.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _supabaseService.usunMiejscowke(widget.miejscowkaDoEdycji!.id);
                if (mounted) {
                  _pokazSnackBar('Miejsce zostało usunięte.');
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) _pokazSnackBar('Błąd usuwania: $e', blad: true);
              } finally {
                if (mounted) setState(() => _isLoading = false);
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
        title: Text(
          widget.miejscowkaDoEdycji != null ? 'Edytuj Miejsce' : 'Dodaj Miejsce',
          style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.tealAccent),
        elevation: 0,
        actions: [
          if (widget.miejscowkaDoEdycji != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Usuń miejsce',
              onPressed: _pokazDialogUsuwania,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[850]),
        ),
      ),
      body: _loadingKategorie
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _naglowekSekcji('Podstawowe informacje'),
                    const SizedBox(height: 12),
                    _pole(
                      kontroler: _nazwaCtrl,
                      label: 'Nazwa miejsca',
                      ikona: Icons.place,
                      walidator: (v) => (v == null || v.trim().isEmpty) ? 'Podaj nazwę' : null,
                    ),
                    const SizedBox(height: 14),
                    _pole(kontroler: _opisCtrl, label: 'Opis', ikona: Icons.notes, maxLines: 3),
                    const SizedBox(height: 24),

                    _naglowekSekcji('Lokalizacja'),
                    const SizedBox(height: 8),
                    LokalizacjaPicker(
                      wybranaLokalizacja: wybranaLokalizacja,
                      onLocationChanged: (point) => setState(() => wybranaLokalizacja = point),
                    ),
                    const SizedBox(height: 24),

                    _naglowekSekcji('Szczegóły'),
                    const SizedBox(height: 12),
                    CzasOtwarciaRow(
                      czasOtwarcia: czasOtwarcia,
                      czasZamkniecia: czasZamkniecia,
                      onOtwarcieChanged: (t) => setState(() => czasOtwarcia = t),
                      onZamkniecieChanged: (t) => setState(() => czasZamkniecia = t),
                    ),
                    const SizedBox(height: 14),
                    _pole(
                      kontroler: _zdjecieCtrl,
                      label: 'URL zdjęć (oddziel linki przecinkiem)',
                      ikona: Icons.image_outlined,
                      typ: TextInputType.url,
                    ),
                    const SizedBox(height: 14),
                    KategoriaDropdown(
                      kategorie: _kategorie,
                      wybranaKategoriaId: _wybranaKategoriaId,
                      onChanged: (val) => setState(() => _wybranaKategoriaId = val),
                      onDodajKategorie: _supabaseService.dodajKategorie,
                      onKategoriaAdded: (nowaKat) => setState(() {
                        _kategorie.add(nowaKat);
                        _wybranaKategoriaId = nowaKat.id;
                      }),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _zapisz,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : const Icon(Icons.save_alt, color: Colors.black),
                        label: Text(
                          _isLoading ? 'Zapisywanie...' : 'Zapisz',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          disabledBackgroundColor: Colors.tealAccent.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _naglowekSekcji(String tekst) {
    return Text(
      tekst,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _pole({
    required TextEditingController kontroler,
    required String label,
    required IconData ikona,
    String? podpowiedz,
    int maxLines = 1,
    TextInputType typ = TextInputType.text,
    String? Function(String?)? walidator,
  }) {
    return TextFormField(
      controller: kontroler,
      maxLines: maxLines,
      keyboardType: typ,
      style: const TextStyle(color: Colors.white),
      validator: walidator,
      decoration: InputDecoration(
        labelText: label,
        hintText: podpowiedz,
        labelStyle: TextStyle(color: Colors.grey[500]),
        hintStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(ikona, color: Colors.grey[600]),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
