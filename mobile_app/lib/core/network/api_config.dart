/// Backend base URL, resolved at build/run time via `--dart-define-from-file`.
///
/// Defaults to the permanently hosted production backend
/// (https://govi-ai.fly.dev), so `flutter run` works with no dart-define
/// file at all and no local backend running.
///
/// To point at a local backend during development instead, copy
/// `dart_define.example.json` to `dart_define.json` (gitignored), set
/// `API_BASE_URL` to your machine's LAN IP, then run with:
///   flutter run --dart-define-from-file=dart_define.json
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://govi-ai.fly.dev/api/v1',
  );
}
