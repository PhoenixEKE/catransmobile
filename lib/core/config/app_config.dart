import 'package:flutter/foundation.dart';

class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const Set<String> _releaseBlockedHosts = <String>{
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  };

  static void validateRuntimeConfiguration() {
    validateApiBaseUrlOrThrow(
      value: apiBaseUrl,
      isReleaseMode: kReleaseMode,
    );
  }

  static void validateApiBaseUrlOrThrow({
    required String value,
    required bool isReleaseMode,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError(_buildApiBaseUrlError(
        'API_BASE_URL is missing or empty.',
      ));
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      throw StateError(_buildApiBaseUrlError(
        'API_BASE_URL is not a valid URL.',
      ));
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw StateError(_buildApiBaseUrlError(
        'API_BASE_URL must use HTTP or HTTPS.',
      ));
    }

    if (uri.host.isEmpty) {
      throw StateError(_buildApiBaseUrlError(
        'API_BASE_URL must include a host.',
      ));
    }

    final host = uri.host.toLowerCase();
    if (isReleaseMode && _releaseBlockedHosts.contains(host)) {
      throw StateError(_buildApiBaseUrlError(
        'API_BASE_URL cannot target localhost in release builds.',
      ));
    }
  }

  static String _buildApiBaseUrlError(String reason) {
    return '$reason Set API_BASE_URL with '
        '--dart-define=API_BASE_URL=<http(s)://host/api/v1>.';
  }
}
