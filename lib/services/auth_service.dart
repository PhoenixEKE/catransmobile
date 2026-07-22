import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/core/storage/token_storage.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/services/api/auth_api_service.dart';

class AuthService extends ChangeNotifier {
  final AuthApiService _authApiService;
  final TokenStorage _tokenStorage;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AuthService({
    AuthApiService? authApiService,
    TokenStorage? tokenStorage,
  })  : _authApiService = authApiService ?? AuthApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Whether [loadUser] has completed at least once since app start. The
  /// go_router redirect guard (`lib/core/navigation/app_router.dart`) uses
  /// this to avoid guarding a protected route before auth state is known.
  bool get isInitialized => _isInitialized;

  Future<void> loadUser() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _token = null;
        _currentUser = null;
        return;
      }

      _token = accessToken;
      _currentUser = await _authApiService.me();
    } catch (error) {
      await _tokenStorage.clearTokens();
      _token = null;
      _currentUser = null;
      _errorMessage = _readableErrorMessage(error);
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final tokens = await _authApiService.login(
        phoneNumber: phone,
        password: password,
      );

      await _tokenStorage.saveTokens(
        accessToken: tokens.access,
        refreshToken: tokens.refresh,
      );

      _token = tokens.access;
      _currentUser = await _authApiService.me();
      _setLoading(false);
      return true;
    } catch (error) {
      await _tokenStorage.clearTokens();
      _token = null;
      _currentUser = null;
      _errorMessage = _readableErrorMessage(error);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> loginInternal(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final tokens = await _authApiService.loginInternal(
        email: email,
        password: password,
      );

      await _tokenStorage.saveTokens(
        accessToken: tokens.access,
        refreshToken: tokens.refresh,
      );

      _token = tokens.access;
      _currentUser = await _authApiService.me();
      _setLoading(false);
      return true;
    } catch (error) {
      await _tokenStorage.clearTokens();
      _token = null;
      _currentUser = null;
      _errorMessage = _readableErrorMessage(error);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String lastname,
    required String firstname,
    required String phone,
    required String password,
    required String passwordConfirm,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final tokens = await _authApiService.register(
        lastname: lastname,
        firstname: firstname,
        phoneNumber: phone,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      await _tokenStorage.saveTokens(
        accessToken: tokens.access,
        refreshToken: tokens.refresh,
      );

      _token = tokens.access;
      _currentUser = await _authApiService.me();
      _setLoading(false);
      return true;
    } catch (error) {
      await _tokenStorage.clearTokens();
      _token = null;
      _currentUser = null;
      _errorMessage = _readableErrorMessage(error);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    String? lastname,
    String? firstname,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authApiService.updateClientProfile(
        lastname: lastname,
        firstname: firstname,
      );
      _currentUser = await _authApiService.me();
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = _readableErrorMessage(error);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    await _clearLegacySession();

    _currentUser = null;
    _token = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _clearLegacySession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _readableErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
