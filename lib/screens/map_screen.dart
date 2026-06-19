import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/miejscowka.dart';
import '../models/kategoria.dart';
import '../services/supabase_service.dart';
import '../widgets/miejscowka_bottom_sheet.dart';
import '../widgets/mapa_filter_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
    }

    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(50.0614, 19.9372),
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.miejscowy_app',
            ),
            MarkerLayer(
              markers: _miejscowki
                  .where((m) => wybranyFiltr == 'Wszystkie' || m.kategoria?.nazwa == wybranyFiltr)
                  .map(
                    (miejscowka) => Marker(
                      point: LatLng(miejscowka.szerokoscGeo, miejscowka.dlugoscGeo),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => MiejscowkaBottomSheet.show(
                          context,
                          miejscowka: miejscowka,
                          onDataChanged: _loadDane,
                          onDelete: _supabaseService.usunMiejscowke,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.tealAccent, size: 40),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        MapaFilterBar(
          kategorie: _kategorie,
          wybranyFiltr: wybranyFiltr,
          onFiltrChanged: (filtr) => setState(() => wybranyFiltr = filtr),
        ),
      ],
    );
  }
}
