class ApiConfig {
  /// Override at build time: --dart-define=API_BASE_URL=http://192.168.1.5:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
