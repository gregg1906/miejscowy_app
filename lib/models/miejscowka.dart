import 'kategoria.dart';

class Miejscowka {
  final String id;
  final String nazwa;
  final String opis;
  final String? kategoriaId;
  final double szerokoscGeo;
  final double dlugoscGeo;
  final String godzinyOtwarcia;
  final List<String> zdjeciaUrl;
  final Kategoria? kategoria;

  Miejscowka({
    required this.id,
    required this.nazwa,
    required this.opis,
    this.kategoriaId,
    required this.szerokoscGeo,
    required this.dlugoscGeo,
    required this.godzinyOtwarcia,
    required this.zdjeciaUrl,
    this.kategoria,
  });

  factory Miejscowka.fromJson(Map<String, dynamic> json) {
    // Safe casting for zdjecia_url List
    final rawZdjecia = json['zdjecia_url'];
    final List<String> zdjeciaList = rawZdjecia != null
        ? List<String>.from(rawZdjecia as List)
        : [];

    // Parse kategoria relation if present in JSON under 'kategorie'
    Kategoria? kategoriaObj;
    if (json['kategorie'] != null) {
      if (json['kategorie'] is Map) {
        kategoriaObj = Kategoria.fromJson(Map<String, dynamic>.from(json['kategorie'] as Map));
      } else if (json['kategorie'] is List && (json['kategorie'] as List).isNotEmpty) {
        kategoriaObj = Kategoria.fromJson(Map<String, dynamic>.from(json['kategorie'][0] as Map));
      }
    }

    return Miejscowka(
      id: json['id'] as String,
      nazwa: json['nazwa'] as String? ?? '',
      opis: json['opis'] as String? ?? '',
      kategoriaId: json['kategoria_id'] as String?,
      szerokoscGeo: (json['szerokosc_geo'] as num?)?.toDouble() ?? 0.0,
      dlugoscGeo: (json['dlugosc_geo'] as num?)?.toDouble() ?? 0.0,
      godzinyOtwarcia: json['godziny_otwarcia'] as String? ?? '',
      zdjeciaUrl: zdjeciaList,
      kategoria: kategoriaObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nazwa': nazwa,
      'opis': opis,
      'kategoria_id': kategoriaId,
      'szerokosc_geo': szerokoscGeo,
      'dlugosc_geo': dlugoscGeo,
      'godziny_otwarcia': godzinyOtwarcia,
      'zdjecia_url': zdjeciaUrl,
      'kategorie': kategoria?.toJson(),
    };
  }
}
