import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/kategoria.dart';
import '../models/miejscowka.dart';
import '../services/supabase_service.dart';

class AddScreen extends StatefulWidget {
  final Miejscowka? miejscowkaDoEdycji;

  const AddScreen({super.key, this.miejscowkaDoEdycji});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();

  // Kontrolery pól tekstowych
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
      if (mounted) {
        _pokazSnackBar('Błąd zapisu: $e', blad: true);
      }
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
                if (mounted) {
                  _pokazSnackBar('Błąd usuwania: $e', blad: true);
                }
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

  void _pokazDialogDodawaniaKategorii() {
    final nazwaCtrl = TextEditingController();
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
                style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nazwaCtrl,
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
                          final nazwa = nazwaCtrl.text.trim();
                          if (nazwa.isEmpty) return;

                          setDialogState(() => dialogLoading = true);

                          try {
                            final nowaKat = await _supabaseService.dodajKategorie(nazwa);
                            if (mounted) {
                              setState(() {
                                _kategorie.add(nowaKat);
                                _wybranaKategoriaId = nowaKat.id;
                              });
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Błąd: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              setDialogState(() => dialogLoading = false);
                            }
                          }
                        },
                  child: const Text('Zapisz', style: TextStyle(color: Colors.tealAccent)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => nazwaCtrl.dispose());
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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sekcja: Podstawowe info ──────────────────────────────
                    _naglowekSekcji('Podstawowe informacje'),
                    const SizedBox(height: 12),
                    _pole(
                      kontroler: _nazwaCtrl,
                      label: 'Nazwa miejsca',
                      ikona: Icons.place,
                      walidator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Podaj nazwę'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _pole(
                      kontroler: _opisCtrl,
                      label: 'Opis',
                      ikona: Icons.notes,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // ── Sekcja: Lokalizacja (mini-mapa) ─────────────────────
                    _naglowekSekcji('Lokalizacja'),
                    const SizedBox(height: 8),
                    Text(
                      'Wybierz lokalizację na mapie:',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 10),

                    // Wizualna informacja o wybranym punkcie
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: wybranaLokalizacja != null
                          ? Container(
                              key: const ValueKey('coords'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.tealAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.tealAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.tealAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Lat: ${wybranaLokalizacja!.latitude.toStringAsFixed(5)}'
                                      '  |  Lng: ${wybranaLokalizacja!.longitude.toStringAsFixed(5)}',
                                      style: const TextStyle(
                                        color: Colors.tealAccent,
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              key: const ValueKey('no-coords'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    color: Colors.orange[300],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kliknij w mapę, aby wybrać punkt',
                                    style: TextStyle(
                                      color: Colors.orange[300],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // Mini-mapa interaktywna
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 250,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: const LatLng(50.0614, 19.9372),
                            initialZoom: 12,
                            onTap: (tapPosition, point) {
                              setState(() {
                                wybranaLokalizacja = point;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.example.miejscowy_app',
                            ),
                            if (wybranaLokalizacja != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: wybranaLokalizacja!,
                                    width: 44,
                                    height: 44,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.tealAccent,
                                      size: 44,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Sekcja: Szczegóły ────────────────────────────────────
                    _naglowekSekcji('Szczegóły'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: czasOtwarcia ?? const TimeOfDay(hour: 9, minute: 0),
                                builder: (BuildContext context, Widget? child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => czasOtwarcia = picked);
                              }
                            },
                            icon: const Icon(Icons.access_time, color: Colors.tealAccent, size: 20),
                            label: Text(
                              czasOtwarcia != null
                                  ? 'Od: ${czasOtwarcia!.hour.toString().padLeft(2, '0')}:${czasOtwarcia!.minute.toString().padLeft(2, '0')}'
                                  : 'Otwarcie',
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
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: czasZamkniecia ?? const TimeOfDay(hour: 18, minute: 0),
                                builder: (BuildContext context, Widget? child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => czasZamkniecia = picked);
                              }
                            },
                            icon: const Icon(Icons.access_time_filled, color: Colors.tealAccent, size: 20),
                            label: Text(
                              czasZamkniecia != null
                                  ? 'Do: ${czasZamkniecia!.hour.toString().padLeft(2, '0')}:${czasZamkniecia!.minute.toString().padLeft(2, '0')}'
                                  : 'Zamknięcie',
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
                    ),
                    const SizedBox(height: 14),
                    _pole(
                      kontroler: _zdjecieCtrl,
                      label: 'URL zdjęć (oddziel linki przecinkiem)',
                      ikona: Icons.image_outlined,
                      typ: TextInputType.url,
                    ),
                    const SizedBox(height: 14),

                    // ── Dropdown kategorii ───────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(_wybranaKategoriaId),
                            initialValue: _wybranaKategoriaId,
                            decoration: InputDecoration(
                              labelText: 'Kategoria',
                              labelStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.category,
                                color: Colors.grey[600],
                              ),
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
                                borderSide: const BorderSide(
                                  color: Colors.tealAccent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white),
                            hint: Text(
                              'Wybierz kategorię',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            items: _kategorie.map((kat) {
                              return DropdownMenuItem<String>(
                                value: kat.id,
                                child: Text(kat.nazwa),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _wybranaKategoriaId = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.tealAccent,
                            size: 30,
                          ),
                          tooltip: 'Dodaj nową kategorię',
                          onPressed: _pokazDialogDodawaniaKategorii,
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // ── Przycisk Zapisz ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _zapisz,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_alt, color: Colors.black),
                        label: Text(
                          _isLoading ? 'Zapisywanie...' : 'Zapisz',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          disabledBackgroundColor: Colors.tealAccent.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
