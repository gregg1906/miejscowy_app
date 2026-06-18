#  Miejscówy App 

##  Stack 

* **Frontend:** Flutter
* **Backend/Baza danych:** Supabase (PostgreSQL)

##  Wymagania 

Aby uruchomić projekt potrzebujesz:
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Edytor (np. VS Code, Android Studio)
* Kluczy dostępowych do bazy Supabase.

##  Uruchomienie krok po kroku

1. Sklonuj repozytorium na swój komputer:
   ```bash
   git clone [https://github.com/gregg1906/miejscowy_app.git](https://github.com/gregg1906/miejscowy_app.git)
   ```

2. Przejdź do głównego folderu z projektem:
   ```bash
   cd miejscowy_app
   ```

3. Pobierz wszystkie wymagane pakiety i zależności:
   ```bash
   flutter pub get
   ```

4. **Skonfiguruj połączenie z bazą:**
   * W folderze `lib/` utwórz plik o nazwie `constants.dart`.
   * Wklej do niego swoje klucze API z panelu Supabase:
     ```dart
     const String supabaseUrl = 'TWÓJ_URL_Z_SUPABASE';
     const String supabaseAnonKey = 'TWÓJ_KLUCZ_ANON_Z_SUPABASE';
     ```

5. **Uruchom aplikację:**
   * Na podłączonym telefonie lub emulatorze:
     ```bash
     flutter run
     ```
   * **W przeglądarce (Zalecane do testów):**
     ```bash
     flutter run -d chrome --web-browser-flag "--disable-web-security"
     ```

##  Struktura

* `lib/screens/` - Główne widoki (Mapa, Lista, Formularz, Menedżer Kategorii).
* `lib/models/` - Modele danych obiektowych (Mapowanie struktury JSON z Supabase na obiekty Dart).
* `lib/services/` - Logika komunikacji z backendem (`supabase_service.dart`).
* `lib/main.dart` - Punkt wejścia aplikacji, definicja motywu i inicjalizacja bazy.