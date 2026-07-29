import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/loyalty/loyalty_account.dart';
import 'package:catrans_app/models/loyalty/loyalty_transaction.dart';

class LoyaltyApiService {
  final ApiClient _apiClient;

  LoyaltyApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<LoyaltyAccount> getAccount() async {
    final response = await _apiClient.get('client/loyalty/');
    return LoyaltyAccount.fromJson(_readObject(response.data));
  }

  Future<LoyaltyTransactionsPage> listTransactions() async {
    final response = await _apiClient.get('client/loyalty/transactions/');
    return LoyaltyTransactionsPage.fromJson(_readObject(response.data));
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException(message: 'Réponse API invalide.', details: data);
  }
}
