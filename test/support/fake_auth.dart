import 'package:dio/dio.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/core/storage/token_storage.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/auth/auth_tokens.dart';
import 'package:catrans_app/services/api/auth_api_service.dart';

/// Client HTTP local aux tests.
///
/// L'URL est syntaxiquement valide, mais aucun appel réseau réel n'est effectué,
/// car toutes les méthodes utilisées par les tests sont surchargées dans
/// [FakeAuthApiService].
ApiClient _buildTestApiClient() {
  return ApiClient(
    dio: Dio(
      BaseOptions(
        baseUrl: 'https://test.invalid/api/v1/',
      ),
    ),
  );
}

/// Stockage de tokens en mémoire pour les widget tests.
///
/// Ce fake évite toute dépendance au canal de plateforme
/// `flutter_secure_storage`.
class FakeTokenStorage extends TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  void seedAccessToken(String token) {
    _accessToken = token;
  }
}

/// Faux service d'authentification pilotable par les tests.
///
/// Le constructeur injecte explicitement un [ApiClient] de test afin d'éviter
/// que le constructeur parent utilise l'URL vide provenant de [AppConfig].
///
/// Toutes les méthodes susceptibles d'accéder au réseau sont surchargées.
class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService() : super(apiClient: _buildTestApiClient());

  User? userOnMe;

  bool failLoginInternal = false;
  bool failLogin = false;

  String failureMessage = 'Email ou mot de passe incorrect';

  @override
  Future<AuthTokens> loginInternal({
    required String email,
    required String password,
  }) async {
    if (failLoginInternal) {
      throw ApiException(message: failureMessage);
    }

    return const AuthTokens(
      access: 'fake-internal-access',
      refresh: 'fake-internal-refresh',
    );
  }

  @override
  Future<AuthTokens> login({
    required String phoneNumber,
    required String password,
  }) async {
    if (failLogin) {
      throw ApiException(message: failureMessage);
    }

    return const AuthTokens(
      access: 'fake-client-access',
      refresh: 'fake-client-refresh',
    );
  }

  @override
  Future<User> me() async {
    final user = userOnMe;

    if (user == null) {
      throw ApiException(
        message: 'Utilisateur introuvable.',
      );
    }

    return user;
  }
}
