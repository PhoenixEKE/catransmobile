class AppConfig {
  // Chrome local: http://127.0.0.1:8000/api/v1
  // Samsung Android physique: utiliser http://IP_DU_PC:8000/api/v1
  // Android emulator: http://10.0.2.2:8000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );
}
