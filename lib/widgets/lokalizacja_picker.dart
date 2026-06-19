import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class LokalizacjaPicker extends StatelessWidget {
  final LatLng? wybranaLokalizacja;
  final ValueChanged<LatLng> onLocationChanged;

  const LokalizacjaPicker({
    super.key,
    required this.wybranaLokalizacja,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wybierz lokalizację na mapie:',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: wybranaLokalizacja != null
              ? _BanerKoordinatow(key: const ValueKey('coords'), lokalizacja: wybranaLokalizacja!)
              : _BanerWskazowki(key: const ValueKey('no-coords')),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: wybranaLokalizacja ?? const LatLng(50.0614, 19.9372),
                initialZoom: 12,
                onTap: (_, point) => onLocationChanged(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
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
                        child: const Icon(Icons.location_on, color: Colors.tealAccent, size: 44),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BanerKoordinatow extends StatelessWidget {
  final LatLng lokalizacja;

  const _BanerKoordinatow({super.key, required this.lokalizacja});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.tealAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lat: ${lokalizacja.latitude.toStringAsFixed(5)}  |  Lng: ${lokalizacja.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BanerWskazowki extends StatelessWidget {
  const _BanerWskazowki({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app, color: Colors.orange[300], size: 18),
          const SizedBox(width: 8),
          Text(
            'Kliknij w mapę, aby wybrać punkt',
            style: TextStyle(color: Colors.orange[300], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
