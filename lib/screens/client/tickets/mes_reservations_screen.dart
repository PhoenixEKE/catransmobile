import 'package:flutter/material.dart';
import 'package:catrans_app/screens/client/tickets/billet_screen.dart';

class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});

  @override
  _MesReservationsScreenState createState() => _MesReservationsScreenState();
}

class _MesReservationsScreenState extends State<MesReservationsScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _reservationsAVenir = [
    {
      'id': '1',
      'depart': 'Dakar',
      'arrivee': 'Saint-Louis',
      'date': DateTime.now().add(const Duration(days: 5)),
      'heure': '08:00',
      'statut': 'Confirmée',
      'classe': 'prestige',
      'prix': 3500,
      'reference': 'CIT-20240101-12345',
      'passagers': [
        {'nom': 'Diop', 'prenom': 'Aminata', 'place': 7},
        {'nom': 'Fall', 'prenom': 'Moussa', 'place': 8},
      ],
    },
    {
      'id': '2',
      'depart': 'Dakar',
      'arrivee': 'Thiès',
      'date': DateTime.now().add(const Duration(days: 2)),
      'heure': '14:30',
      'statut': 'Confirmée',
      'classe': 'economie',
      'prix': 1500,
      'reference': 'CIT-20240102-67890',
      'passagers': [
        {'nom': 'Sow', 'prenom': 'Fatou', 'place': 0},
      ],
    },
  ];

  final List<Map<String, dynamic>> _reservationsPassees = [
    {
      'id': '3',
      'depart': 'Thiès',
      'arrivee': 'Mbour',
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'heure': '10:00',
      'statut': 'Terminée',
      'classe': 'economie',
      'prix': 2000,
      'reference': 'CIT-20231220-11111',
      'passagers': [
        {'nom': 'Ndiaye', 'prenom': 'Mamadou', 'place': 12},
      ],
    },
    {
      'id': '4',
      'depart': 'Dakar',
      'arrivee': 'Kaolack',
      'date': DateTime.now().subtract(const Duration(days: 25)),
      'heure': '07:30',
      'statut': 'Annulée',
      'classe': 'prestige',
      'prix': 4000,
      'reference': 'CIT-20231205-22222',
      'passagers': [
        {'nom': 'Ba', 'prenom': 'Khady', 'place': 5},
      ],
    },
  ];

  String _formatDate(DateTime date) {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getMonth(DateTime date) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[date.month - 1];
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'Confirmée':
        return Colors.green;
      case 'Terminée':
        return Colors.blue;
      case 'Annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentReservations = _selectedTab == 0 ? _reservationsAVenir : _reservationsPassees;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Mes Réservations'),
          backgroundColor: const Color(0xFF0F056B),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'À VENIR'),
              Tab(text: 'PASSÉES'),
            ],
            indicatorColor: Color(0xFFEFD807),
            labelColor: Color(0xFFEFD807),
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildReservationList(_reservationsAVenir, 'à venir'),
            _buildReservationList(_reservationsPassees, 'passées'),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationList(List<Map<String, dynamic>> reservations, String type) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'à venir' ? Icons.airplane_ticket_outlined : Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              type == 'à venir' ? 'Aucune réservation à venir' : 'Aucune réservation passée',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              type == 'à venir' ? 'Réservez votre prochain trajet' : 'Vos réservations apparaîtront ici',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 30),
            if (type == 'à venir')
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFD807),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('RECHERCHER UN TRAJET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        final date = reservation['date'] as DateTime;
        final passagers = reservation['passagers'] as List;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BilletScreen(
                  depart: reservation['depart'],
                  arrivee: reservation['arrivee'],
                  date: date,
                  heure: reservation['heure'],
                  classe: reservation['classe'],
                  prix: reservation['prix'],
                  nombrePassagers: passagers.length,
                  passagers: passagers.cast<Map<String, dynamic>>(),
                  reference: reservation['reference'],
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F056B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.day.toString(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F056B)),
                        ),
                        Text(
                          _getMonth(date),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F056B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reservation['depart'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                            Text(
                              reservation['arrivee'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(reservation['heure'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: reservation['classe'] == 'prestige'
                                    ? const Color(0xFFEFD807).withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                reservation['classe'].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: reservation['classe'] == 'prestige'
                                      ? const Color(0xFFEFD807)
                                      : Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.people, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${passagers.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatutColor(reservation['statut']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatutColor(reservation['statut'])),
                    ),
                    child: Text(
                      reservation['statut'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatutColor(reservation['statut']),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}