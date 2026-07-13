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
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ),
        _tokenStorage = tokenStorage ?? TokenStorage() {
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
  }) {
    return _guard(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return _guard(() => _dio.post<dynamic>(path, data: data));
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) {
    return _guard(() => _dio.patch<dynamic>(path, data: data));
  }

  Future<Response<dynamic>> delete(String path, {dynamic data}) {
    return _guard(() => _dio.delete<dynamic>(path, data: data));
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
        '/auth/token/refresh/',
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
        requestOptions.path,
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
      message: _readErrorMessage(response?.data) ??
          error.message ??
          'Une erreur API est survenue.',
      statusCode: response?.statusCode,
      details: response?.data,
    );
  }

  String? _readErrorMessage(dynamic data) {
    if (data is String && data.isNotEmpty) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      for (final key in ['detail', 'message', 'error', 'non_field_errors']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
        if (value is List && value.isNotEmpty) {
          return value.join(', ');
        }
      }
    }

    return null;
  }
}
