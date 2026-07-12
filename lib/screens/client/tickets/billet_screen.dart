import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:catrans_app/screens/client/home/accueil_screen.dart';

class BilletScreen extends StatelessWidget {
  final String depart;
  final String arrivee;
  final DateTime date;
  final String heure;
  final String classe;
  final double prix;
  final int nombrePassagers;
  final List<Map<String, dynamic>> passagers;
  final String reference;

  const BilletScreen({
    super.key,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.heure,
    required this.classe,
    required this.prix,
    required this.nombrePassagers,
    required this.passagers,
    required this.reference,
  });

  String _formatDate(DateTime date) {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _shareBillet(BuildContext context) {
    final String message = '''
┌─────────────────────────────┐
│         🚌 CITRANS          │
│                              │
│   Référence: $reference     │
│   Trajet: $depart → $arrivee│
│   Date: ${_formatDate(date)}│
│   Heure: $heure              │
│   Classe: ${classe.toUpperCase()}│
│   Passagers: $nombrePassagers│
│   Prix: ${(prix * nombrePassagers).toStringAsFixed(0)} FCFA│
│                              │
│   Présentez ce QR code à    │
│   l'embarquement            │
└─────────────────────────────┘
''';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mon Billet'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareBillet(context),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Billet
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F056B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/icons/logo.png',
                            height: 40,
                            width: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.directions_bus, size: 30, color: Colors.white);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'CITRANS',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFD807),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MOBILE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Référence', reference, icon: Icons.confirmation_number),
                        const Divider(height: 24),
                        _buildInfoRow('Trajet', '$depart → $arrivee', icon: Icons.route),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow('Date', _formatDate(date), icon: Icons.calendar_today),
                            ),
                            Expanded(
                              child: _buildInfoRow('Heure', heure, icon: Icons.access_time),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Classe', classe.toUpperCase(), icon: Icons.stars),
                        const SizedBox(height: 12),
                        const Text(
                          'Passagers',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F056B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...passagers.map((passager) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F056B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${passager['place'] ?? '?'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F056B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${passager['prenom']} ${passager['nom']}'),
                              const Spacer(),
                              if (passager['place'] != 0)
                                Text(
                                  'Siège N°${passager['place']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: '$reference|$depart|$arrivee|${DateTime.now().millisecondsSinceEpoch}',
                                  size: 150,
                                  backgroundColor: Colors.white,
                                  version: QrVersions.auto,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Présentez ce QR code à l\'embarquement',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F056B).withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prix total',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${(prix * nombrePassagers).toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F056B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}