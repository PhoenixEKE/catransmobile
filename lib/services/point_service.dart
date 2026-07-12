import 'package:catrans_app/models/loyalty/loyalty_account.dart';
import 'package:catrans_app/models/accounts/customer_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PointService {
  static final PointService _instance = PointService._internal();
  factory PointService() => _instance;
  PointService._internal();

  LoyaltyAccount? _account;

  Future<LoyaltyAccount> chargerCompte(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('loyalty_$userId');
    
    if (data != null) {
      final json = jsonDecode(data);
      _account = LoyaltyAccount.fromJson(json);
    } else {
      // Créer un User fictif pour le test
      final user = User(
        id: userId,
        lastname: 'Test',
        firstname: 'User',
        phoneNumber: '771234567',
        passwordHash: 'hashed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final customer = CustomerProfile(
        id: 'test_customer_$userId',
        user: user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _account = LoyaltyAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customer: customer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await sauvegarder();
    }
    return _account!;
  }

  Future<void> sauvegarder() async {
    if (_account == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'loyalty_${_account!.id}',
      jsonEncode(_account!.toJson()),
    );
  }

  Future<bool> ajouterPoints(String userId, int points, String classe, String trajetInfo) async {
    await chargerCompte(userId);
    if (_account == null) return false;
    
    _account = LoyaltyAccount(
      id: _account!.id,
      customer: _account!.customer,
      balancePoints: _account!.balancePoints + points,
      totalEarnedPoints: _account!.totalEarnedPoints + points,
      totalSpentPoints: _account!.totalSpentPoints,
      createdAt: _account!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    await sauvegarder();
    return true;
  }

  Future<Map<String, dynamic>> getInfoPoints(String userId) async {
    await chargerCompte(userId);
    return {
      'balance': _account?.balancePoints ?? 0,
      'totalEarned': _account?.totalEarnedPoints ?? 0,
      'totalSpent': _account?.totalSpentPoints ?? 0,
    };
  }
}