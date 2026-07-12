import 'package:flutter/material.dart';

class ReportModificationScreen extends StatefulWidget {
  const ReportModificationScreen({super.key});

  @override
  _ReportModificationScreenState createState() => _ReportModificationScreenState();
}

class _ReportModificationScreenState extends State<ReportModificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showModification = false;

  final List<Map<String, dynamic>> _reservations = [
    {'id': 'CIT-2024-001', 'client': 'Amadou Diop', 'trajet': 'Dakar → Saint-Louis', 'date': '15/07/2024', 'heure': '08:00', 'siege': 7},
    {'id': 'CIT-2024-002', 'client': 'Fatou Sow', 'trajet': 'Dakar → Thiès', 'date': '16/07/2024', 'heure': '10:30', 'siege': 12},
    {'id': 'CIT-2024-003', 'client': 'Moussa Ndiaye', 'trajet': 'Thiès → Mbour', 'date': '17/07/2024', 'heure': '14:00', 'siege': 3},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Report / Modification'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rechercher une réservation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F056B)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Référence, nom client...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => _showModification = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F056B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        child: const Text('RECHERCHER'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_showModification)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _buildCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat de la recherche',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._reservations
                        .where((r) => r['id'].contains(_searchController.text) ||
                            r['client'].contains(_searchController.text))
                        .map((reservation) => _buildReservationItem(reservation))
                        .toList(),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (_showModification)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _buildCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modifications disponibles',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F056B)),
                    ),
                    const SizedBox(height: 12),
                    _buildModificationItem('Report de voyage', Icons.calendar_today, 'Reporter à une autre date'),
                    _buildModificationItem('Modification date', Icons.date_range, 'Changer la date du voyage'),
                    _buildModificationItem('Modification heure', Icons.access_time, 'Changer l\'heure de départ'),
                    _buildModificationItem('Changement siège', Icons.event_seat, 'Changer le numéro de siège'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Historique des modifications',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          const Text('3 modifications'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationItem(Map<String, dynamic> reservation) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reservation['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(reservation['client'], style: const TextStyle(fontSize: 12)),
                Text(
                  '${reservation['trajet']} • ${reservation['date']} ${reservation['heure']} • Siège ${reservation['siege']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F056B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('MODIFIER'),
          ),
        ],
      ),
    );
  }

  Widget _buildModificationItem(String label, IconData icon, String description) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F056B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF0F056B)),
      ),
      title: Text(label),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}