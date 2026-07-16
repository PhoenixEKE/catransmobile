import 'package:dio/dio.dart';

import 'package:catrans_app/core/config/app_config.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/core/storage/token_storage.dart';

class ApiClient {
  static const String _skipAuthHeaderKey = 'skipAuthHeader';
  static const String _hasRetriedKey = 'hasRetriedAfterRefresh';

  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;

  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _normalizeBaseUrl(AppConfig.apiBaseUrl),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio.options.baseUrl = _normalizeBaseUrl(_dio.options.baseUrl);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra[_skipAuthHeaderKey] == true) {
            handler.next(options);
            return;
          }

          final accessToken = await _tokenStorage.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (_canAttemptRefresh(error)) {
            try {
              final response =
                  await _refreshTokenAndRetry(error.requestOptions);
              handler.resolve(response);
              return;
            } on ApiException {
              await _tokenStorage.clearTokens();
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => _dio.get<dynamic>(
        _normalizePath(path),
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return _guard(() => _dio.post<dynamic>(_normalizePath(path), data: data));
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) {
    return _guard(() => _dio.patch<dynamic>(_normalizePath(path), data: data));
  }

  Future<Response<dynamic>> delete(String path, {dynamic data}) {
    return _guard(() => _dio.delete<dynamic>(_normalizePath(path), data: data));
  }

  static String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  static String _normalizePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    return path.startsWith('/') ? path.substring(1) : path;
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  bool _canAttemptRefresh(DioException error) {
    final statusCode = error.response?.statusCode;
    final requestOptions = error.requestOptions;

    return statusCode == 401 &&
        !_isRefreshing &&
        requestOptions.extra[_skipAuthHeaderKey] != true &&
        requestOptions.extra[_hasRetriedKey] != true;
  }

  Future<Response<dynamic>> _refreshTokenAndRetry(
    RequestOptions requestOptions,
  ) async {
    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw ApiException(
          message: 'Session expirée. Veuillez vous reconnecter.',
          statusCode: 401,
        );
      }

      final refreshResponse = await _dio.post<dynamic>(
        _normalizePath('auth/token/refresh/'),
        data: {'refresh': refreshToken},
        options: Options(extra: {_skipAuthHeaderKey: true}),
      );

      final newAccessToken = _readAccessToken(refreshResponse.data);
      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw ApiException(
          message: 'Réponse de rafraîchissement JWT invalide.',
          statusCode: refreshResponse.statusCode,
          details: refreshResponse.data,
        );
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );

      final headers = Map<String, dynamic>.from(requestOptions.headers);
      headers['Authorization'] = 'Bearer $newAccessToken';

      return _dio.request<dynamic>(
        _normalizePath(requestOptions.path),
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: Options(
          method: requestOptions.method,
          headers: headers,
          responseType: requestOptions.responseType,
          contentType: requestOptions.contentType,
          extra: {
            ...requestOptions.extra,
            _hasRetriedKey: true,
          },
        ),
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    } finally {
      _isRefreshing = false;
    }
  }

  String? _readAccessToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      final access = data['access'];
      return access is String ? access : null;
    }

    return null;
  }

  ApiException _toApiException(DioException error) {
    final response = error.response;

    return ApiException(
      message: _extractErrorMessage(response?.data) ??
          _messageFromDioException(error),
      statusCode: response?.statusCode,
      details: response?.data ?? _diagnosticsFromDioException(error),
    );
  }

  String _messageFromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connexion au serveur trop lente. Veuillez réessayer.';
      case DioExceptionType.sendTimeout:
        return 'Envoi de la requête trop long. Veuillez réessayer.';
      case DioExceptionType.receiveTimeout:
        return 'Le serveur met trop de temps à répondre. Veuillez réessayer.';
      case DioExceptionType.transformTimeout:
        return 'La réponse du serveur met trop de temps à être traitée. Veuillez réessayer.';
      case DioExceptionType.cancel:
        return 'Requête annulée. Veuillez réessayer.';
      case DioExceptionType.connectionError:
        return 'Connexion au serveur impossible. Vérifiez le réseau.';
      case DioExceptionType.badCertificate:
        return 'Certificat serveur invalide.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return error.message ?? 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  Map<String, dynamic> _diagnosticsFromDioException(DioException error) {
    return {
      'dio_type': error.type.name,
      'message': error.message,
      'method': error.requestOptions.method,
      'path': error.requestOptions.path,
      'query_parameters': error.requestOptions.queryParameters,
    };
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is String && data.isNotEmpty) {
      return data;
    }

    if (data is Map) {
      for (final key in ['detail', 'message', 'error', 'non_field_errors']) {
        final message = _messageFromValue(data[key]);
        if (message != null) return message;
      }

      for (final entry in data.entries) {
        final message = _messageFromValue(entry.value);
        if (message != null) return message;
      }
    }

    return null;
  }

  String? _messageFromValue(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    if (value is List && value.isNotEmpty) {
      final messages = value
          .map(_messageFromValue)
          .whereType<String>()
          .where((message) => message.isNotEmpty)
          .toList();
      return messages.isEmpty ? null : messages.join(', ');
    }

    if (value is Map && value.isNotEmpty) {
      return _extractErrorMessage(value);
    }

    return null;
  }
}
