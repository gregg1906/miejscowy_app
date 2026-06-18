import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/miejscowka.dart';
import '../models/kategoria.dart';
import '../services/supabase_service.dart';
import 'add_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Miejscowka> _miejscowki = [];
  List<Kategoria> _kategorie = [];
  String wybranyFiltr = 'Wszystkie';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDane();
  }

  Future<void> _loadDane() async {
    final wyniki = await Future.wait([
      _supabaseService.pobierzMiejscowki(),
      _supabaseService.pobierzKategorie(),
    ]);
    if (mounted) {
      setState(() {
        _miejscowki = wyniki[0] as List<Miejscowka>;
        _kategorie = wyniki[1] as List<Kategoria>;
        _isLoading = false;
      });
    }
  }

  void _pokazZdjeciePelnyEkran(BuildContext context, String urlZdjecia) {
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
              child: Image.network(urlZdjecia, fit: BoxFit.contain),
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

  void _pokazSzczegoly(BuildContext context, Miejscowka miejscowka) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Uchwyt u góry
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

              // Nazwa miejscówki
              Text(
                miejscowka.nazwa,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Kategoria
              if (miejscowka.kategoria?.nazwa != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    miejscowka.kategoria!.nazwa,
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // Opis
              if (miejscowka.opis.isNotEmpty) ...[
                Text(
                  miejscowka.opis,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[300],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Godziny otwarcia
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

              // Zdjęcia
              if (miejscowka.zdjeciaUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: miejscowka.zdjeciaUrl.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => _pokazZdjeciePelnyEkran(
                            context,
                            miejscowka.zdjeciaUrl[index],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              miejscowka.zdjeciaUrl[index],
                              width: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 160,
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 16),

              // ── Przyciski akcji ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Zamknij
                  TextButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Zamknij'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                    ),
                  ),

                  // Edytuj
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddScreen(miejscowkaDoEdycji: miejscowka),
                        ),
                      );
                      _loadDane();
                    },
                    icon: const Icon(Icons.edit, size: 18, color: Colors.black),
                    label: const Text(
                      'Edytuj',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Usuń
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: ctx,
                        builder: (dlgCtx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          title: const Text(
                            'Usuń miejsce',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Czy usunąć "${miejscowka.nazwa}"? Tej operacji nie można cofnąć.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dlgCtx),
                              child: const Text(
                                'Anuluj',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(dlgCtx);
                                Navigator.pop(ctx);
                                try {
                                  await _supabaseService.usunMiejscowke(
                                    miejscowka.id,
                                  );
                                  _loadDane();
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Błąd usuwania: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Tak, usuń',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('Usuń'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(50.0614, 19.9372), // Kraków
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.miejscowy_app',
            ),
            MarkerLayer(
              markers: _miejscowki
                  .where(
                    (m) =>
                        wybranyFiltr == 'Wszystkie' ||
                        m.kategoria?.nazwa == wybranyFiltr,
                  )
                  .map((miejscowka) {
                    return Marker(
                      point: LatLng(
                        miejscowka.szerokoscGeo,
                        miejscowka.dlugoscGeo,
                      ),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _pokazSzczegoly(context, miejscowka),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.tealAccent,
                          size: 40,
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ),
        Positioned(
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
                itemCount: _kategorie.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filtr = index == 0
                      ? 'Wszystkie'
                      : _kategorie[index - 1].nazwa;
                  final wybrany = filtr == wybranyFiltr;
                  return ChoiceChip(
                    label: Text(filtr),
                    selected: wybrany,
                    onSelected: (_) {
                      setState(() {
                        wybranyFiltr = filtr;
                      });
                    },
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
        ),
      ],
    );
  }
}
