import 'package:flutter/material.dart';
import 'package:catrans_app/screens/client/tickets/billet_screen.dart';
import 'package:catrans_app/screens/client/home/accueil_screen.dart';

class ResultatPaiementScreen extends StatelessWidget {
  final bool success;
  final String depart;
  final String arrivee;
  final DateTime date;
  final String heure;
  final double total;
  final int pointsGagnes;
  final String classe;
  final List<Map<String, dynamic>> passagers;

  const ResultatPaiementScreen({
    super.key,
    required this.success,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.heure,
    required this.total,
    required this.pointsGagnes,
    required this.classe,
    required this.passagers,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: success ? Colors.green[50] : Colors.red[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : 60,
            vertical: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: isSmallScreen ? 80 : 120,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 30),
              Text(
                success ? 'Paiement Réussi!' : 'Paiement Échoué',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green[800] : Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                success
                    ? 'Votre réservation a été confirmée'
                    : 'Une erreur est survenue lors du paiement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: success ? Colors.green[600] : Colors.red[600],
                ),
              ),
              const SizedBox(height: 40),

              if (success) ...[
                // Détails - CORRIGÉ avec Expanded
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Trajet', '$depart → $arrivee'),
                      _buildDetailRow('Date', '${date.day}/${date.month}/${date.year}'),
                      _buildDetailRow('Heure', heure),
                      _buildDetailRow('Classe', classe.toUpperCase()),
                      _buildDetailRow('Passagers', '${passagers.length}'),
                      _buildDetailRow('Points gagnés', '+$pointsGagnes pts'),
                      _buildDetailRow('Montant', '${total.toStringAsFixed(0)} FCFA'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Bouton VOIR MON BILLET
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 50 : 55,
                  child: ElevatedButton(
                    onPressed: () {
                      final reference = 'CIT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(6, 12)}';
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BilletScreen(
                            depart: depart,
                            arrivee: arrivee,
                            date: date,
                            heure: heure,
                            classe: classe,
                            prix: total / passagers.length,
                            nombrePassagers: passagers.length,
                            passagers: passagers,
                            reference: reference,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFD807),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSmallScreen ? 'VOIR BILLET' : 'VOIR MON BILLET',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bouton RETOUR ACCUEIL
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 45 : 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AccueilScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home, color: Color(0xFF0F056B)),
                    label: const Text(
                      'RETOUR À L\'ACCUEIL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F056B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F056B), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.error_outline, size: 50, color: Colors.orange),
                      SizedBox(height: 10),
                      Text(
                        'Veuillez vérifier vos informations et réessayer',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 50 : 55,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFD807),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'RÉESSAYER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


