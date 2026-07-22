import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/customer_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/auth/auth_tokens.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<AuthTokens> login({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _apiClient.post(
      'auth/token/',
      data: {
        'phone_number': phoneNumber.trim(),
        'password': password,
      },
    );

    return _readAuthTokens(_readObject(response.data));
  }

  Future<AuthTokens> register({
    required String lastname,
    required String firstname,
    required String phoneNumber,
    required String password,
    required String passwordConfirm,
  }) async {
    final response = await _apiClient.post(
      'auth/register/',
      data: {
        'phone_number': phoneNumber.trim(),
        'lastname': lastname,
        'firstname': firstname,
        'password': password,
        'password_confirm': passwordConfirm,
      },
    );

    return _readAuthTokens(_readObject(response.data));
  }

  Future<AuthTokens> loginInternal({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      'auth/internal/token/',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    return _readAuthTokens(_readObject(response.data));
  }

  Future<String> refreshAccessToken({
    required String refreshToken,
  }) async {
    final response = await _apiClient.post(
      'auth/token/refresh/',
      data: {'refresh': refreshToken},
    );

    final data = _readObject(response.data);
    final accessToken = data['access'];
    if (accessToken is String && accessToken.isNotEmpty) {
      return accessToken;
    }

    throw ApiException(
      message: 'Réponse de rafraîchissement JWT invalide.',
      statusCode: response.statusCode,
      details: response.data,
    );
  }

  Future<User> me() async {
    final response = await _apiClient.get('auth/me/');
    return User.fromJson(_readObject(response.data));
  }

  Future<CustomerProfile> getClientProfile() async {
    final response = await _apiClient.get('client/profile/');
    return CustomerProfile.fromJson(_readObject(response.data));
  }

  Future<CustomerProfile> updateClientProfile({
    String? lastname,
    String? firstname,
  }) async {
    final data = <String, dynamic>{
      if (lastname != null) 'lastname': lastname,
      if (firstname != null) 'firstname': firstname,
    };

    if (data.isEmpty) {
      throw ApiException(
        message: 'Aucune donnée de profil à mettre à jour.',
      );
    }

    final response = await _apiClient.patch(
      'client/profile/',
      data: data,
    );

    return CustomerProfile.fromJson(_readObject(response.data));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _apiClient.post(
      'client/profile/change-password/',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw ApiException(
      message: 'Réponse API invalide.',
      details: data,
    );
  }

  AuthTokens _readAuthTokens(Map<String, dynamic> data) {
    final rawTokens = data['tokens'];
    final tokenData =
        rawTokens is Map ? Map<String, dynamic>.from(rawTokens) : data;

    final access = tokenData['access'];
    final refresh = tokenData['refresh'];

    if (access is String &&
        access.isNotEmpty &&
        refresh is String &&
        refresh.isNotEmpty) {
      return AuthTokens(access: access, refresh: refresh);
    }

    throw ApiException(
      message: 'Réponse d’authentification invalide.',
      details: data,
    );
  }
}
