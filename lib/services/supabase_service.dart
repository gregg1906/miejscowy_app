import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kategoria.dart';
import '../models/miejscowka.dart';

class SupabaseService {
  Future<List<Miejscowka>> pobierzMiejscowki() async {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('miejscowki')
          .select('*, kategorie(*)');

      return response
          .map((json) => Miejscowka.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('Błąd podczas pobierania miejscówek: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Kategoria>> pobierzKategorie() async {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('kategorie')
          .select('*');

      return response
          .map((json) => Kategoria.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('Błąd podczas pobierania kategorii: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> dodajMiejscowke({
    required String nazwa,
    required String opis,
    required double szerokoscGeo,
    required double dlugoscGeo,
    required String godzinyOtwarcia,
    required String zdjecieUrl,
    required String kategoriaId,
  }) async {
    try {
      await Supabase.instance.client.from('miejscowki').insert({
        'nazwa': nazwa,
        'opis': opis,
        'szerokosc_geo': szerokoscGeo,
        'dlugosc_geo': dlugoscGeo,
        'godziny_otwarcia': godzinyOtwarcia,
        'zdjecia_url': zdjecieUrl.isNotEmpty ? [zdjecieUrl] : [],
        'kategoria_id': kategoriaId,
      });
    } catch (e, stackTrace) {
      debugPrint('Błąd podczas dodawania miejscówki: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Kategoria> dodajKategorie(String nazwa) async {
    try {
      final response = await Supabase.instance.client
          .from('kategorie')
          .insert({'nazwa': nazwa})
          .select()
          .single();
      return Kategoria.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e, stackTrace) {
      debugPrint('Błąd podczas dodawania kategorii: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> edytujMiejscowke(String id, Map<String, dynamic> dane) async {
    try {
      await Supabase.instance.client.from('miejscowki').update(dane).eq('id', id);
    } catch (e, stackTrace) {
      debugPrint('Błąd podczas edycji miejscówki: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> usunMiejscowke(String id) async {
    try {
      await Supabase.instance.client.from('miejscowki').delete().eq('id', id);
    } catch (e, stackTrace) {
      debugPrint('Błąd podczas usuwania miejscówki: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> usunKategorie(String id) async {
    try {
      await Supabase.instance.client.from('kategorie').delete().eq('id', id);
    } catch (e, stackTrace) {
      debugPrint('Błąd podczas usuwania kategorii: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> edytujKategorie(String id, String nowaNazwa) async {
    try {
      await Supabase.instance.client
          .from('kategorie')
          .update({'nazwa': nowaNazwa})
          .eq('id', id);
    } catch (e, stackTrace) {
      debugPrint('Błąd podczas edycji kategorii: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
