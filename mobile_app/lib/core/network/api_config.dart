/// Backend base URL, resolved at build/run time via `--dart-define-from-file`.
///
/// Copy `dart_define.example.json` to `dart_define.json` (gitignored) and set
/// `API_BASE_URL` to your machine's LAN IP, then run with:
///   flutter run --dart-define-from-file=dart_define.json
///
/// Without that flag, this falls back to the Android emulator's host alias.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
}
