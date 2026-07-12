import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:catrans_app/models/accounts/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final token = prefs.getString('token');
    
    if (userJson != null && token != null) {
      _token = token;
      _currentUser = User.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (phone.length >= 8 && password.length >= 6) {
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        lastname: 'Diop',
        firstname: 'Amadou',
        phoneNumber: phone,
        passwordHash: 'hashed_password',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _currentUser = user;
      _token = 'token_${DateTime.now().millisecondsSinceEpoch}';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setString('token', _token!);
      
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register({
    required String lastname,
    required String firstname,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (lastname.isNotEmpty && firstname.isNotEmpty && phone.length >= 8 && password.length >= 6) {
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        lastname: lastname,
        firstname: firstname,
        phoneNumber: phone,
        passwordHash: 'hashed_password',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _currentUser = user;
      _token = 'token_${DateTime.now().millisecondsSinceEpoch}';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setString('token', _token!);
      
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    _currentUser = null;
    _token = null;
    notifyListeners();
  }
}
