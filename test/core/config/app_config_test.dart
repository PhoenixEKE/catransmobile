import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/config/app_config.dart';

void main() {
  group('AppConfig.validateApiBaseUrlOrThrow', () {
    test('rejects empty value', () {
      expect(
        () => AppConfig.validateApiBaseUrlOrThrow(
          value: '',
          isReleaseMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects invalid URL', () {
      expect(
        () => AppConfig.validateApiBaseUrlOrThrow(
          value: 'not a url',
          isReleaseMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects URL without host', () {
      expect(
        () => AppConfig.validateApiBaseUrlOrThrow(
          value: 'https:///api/v1',
          isReleaseMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('accepts valid HTTPS URL', () {
      expect(
        () => AppConfig.validateApiBaseUrlOrThrow(
          value: 'https://api.example.com/api/v1',
          isReleaseMode: true,
        ),
        returnsNormally,
      );
    });

    test('accepts local HTTP URL in development mode', () {
      expect(
        () => AppConfig.validateApiBaseUrlOrThrow(
          value: 'http://127.0.0.1:8000/api/v1',
          isReleaseMode: false,
        ),
        returnsNormally,
      );
    });

    test('rejects localhost in release mode', () {
      expect(
        () => AppConfig.validateApiBaseUrlOrThrow(
          value: 'http://localhost:8000/api/v1',
          isReleaseMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects 127.0.0.1 in release mode', () {
      expect(
        () => AppConfig.validateApiBaseUrlOrThrow(
          value: 'http://127.0.0.1:8000/api/v1',
          isReleaseMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects 10.0.2.2 in release mode', () {
      expect(
        () => AppConfig.validateApiBaseUrlOrThrow(
          value: 'http://10.0.2.2:8000/api/v1',
          isReleaseMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('error message mentions API_BASE_URL and dart-define', () {
      try {
        AppConfig.validateApiBaseUrlOrThrow(
          value: '',
          isReleaseMode: true,
        );
        fail('Expected StateError to be thrown');
      } on StateError catch (error) {
        final message = error.message.toString().toString();
        expect(message.contains('API_BASE_URL'), isTrue);
        expect(message.contains('--dart-define=API_BASE_URL='), isTrue);
      }
    });
  });
}
