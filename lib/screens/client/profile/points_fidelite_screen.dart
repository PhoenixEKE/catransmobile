import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/loyalty/loyalty_account.dart';
import 'package:catrans_app/models/loyalty/loyalty_transaction.dart';
import 'package:catrans_app/services/api/loyalty_api_service.dart';

class PointsFideliteScreen extends StatefulWidget {
  const PointsFideliteScreen({super.key});

  @override
  State<PointsFideliteScreen> createState() => _PointsFideliteScreenState();
}

class _PointsFideliteScreenState extends State<PointsFideliteScreen> {
  final _loyaltyApiService = LoyaltyApiService();

  bool _isLoading = true;
  String? _error;
  LoyaltyAccount? _account;
  List<LoyaltyTransaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _loyaltyApiService.getAccount(),
        _loyaltyApiService.listTransactions(),
      ]);
      if (!mounted) return;
      setState(() {
        _account = results[0] as LoyaltyAccount;
        _transactions = (results[1] as LoyaltyTransactionsPage).results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Une erreur est survenue. Veuillez réessayer.';
        _isLoading = false;
      });
    }
  }

  /// Computed from the real transaction history rather than derived from
  /// `lifetime_points - points_balance`: that subtraction would also count
  /// point reversals (a cancelled ticket undoing an earlier earn), which
  /// isn't the same thing as points actually spent on a redemption.
  int get _pointsUsed => _transactions
      .where((t) => t.transactionType.code == 'redemption')
      .fold<int>(0, (sum, t) => sum + t.points.abs());

  @override
  Widget build(BuildContext context) {
    final points = _account?.pointsBalance ?? 0;
    final lifetimePoints = _account?.lifetimePoints ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mes Points de Fidélité'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
      ),
      body: _buildBody(points, lifetimePoints),
    );
  }

  Widget _buildBody(int points, int lifetimePoints) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0F056B)),
            SizedBox(height: 20),
            Text('Chargement de vos points...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 42),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F056B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F056B), Color(0xFF1A1A5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, color: Color(0xFFEFD807), size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Vos Points',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points',
                  style: const TextStyle(
                    color: Color(0xFFEFD807),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${points ~/ 100} billets offerts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prochain niveau',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F056B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Bronze', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.brown[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: (points / 100).clamp(0, 1),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.brown,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$points/100', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Argent', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('100 pts', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Or', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('500 pts', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Résumé',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F056B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Points totaux', points.toString()),
                _buildInfoRow('Points gagnés', lifetimePoints.toString()),
                _buildInfoRow('Points utilisés', _pointsUsed.toString()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historique',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F056B),
                  ),
                ),
                const SizedBox(height: 12),
                if (_transactions.isEmpty)
                  const Text(
                    'Aucun mouvement de points pour le moment.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ..._transactions.map(_buildTransactionRow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(LoyaltyTransaction transaction) {
    final isPositive = transaction.isPositive;
    final label = transaction.description?.trim().isNotEmpty == true
        ? transaction.description!
        : transaction.transactionType.label;
    final createdAt = transaction.createdAt;
    final dateLabel = createdAt != null
        ? DateFormat('d MMM yyyy à HH:mm', 'fr_FR').format(DateTime.parse(createdAt).toLocal())
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${transaction.points} pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? const Color(0xFF027A48) : const Color(0xFFB42318),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
