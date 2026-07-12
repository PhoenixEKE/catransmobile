import 'package:flutter/material.dart';

class ReportModificationScreen extends StatefulWidget {
  const ReportModificationScreen({super.key});

  @override
  _ReportModificationScreenState createState() => _ReportModificationScreenState();
}

class _ReportModificationScreenState extends State<ReportModificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showResult = false;
  String? _selectedReservation;

  final List<Map<String, dynamic>> _reservations = [
    {'id': 'CIT-2024-001', 'client': 'Amadou Diop', 'trajet': 'Dakar → Saint-Louis', 'date': '15/07/2024', 'heure': '08:00', 'siege': 7},
    {'id': 'CIT-2024-002', 'client': 'Fatou Sow', 'trajet': 'Dakar → Thiès', 'date': '16/07/2024', 'heure': '10:30', 'siege': 12},
    {'id': 'CIT-2024-003', 'client': 'Moussa Ndiaye', 'trajet': 'Thiès → Mbour', 'date': '17/07/2024', 'heure': '14:00', 'siege': 3},
  ];

  final List<Map<String, dynamic>> _modifications = [
    {'action': 'Report de voyage', 'date': '12/07/2024', 'status': 'Approuvé'},
    {'action': 'Changement de siège', 'date': '11/07/2024', 'status': 'En attente'},
    {'action': 'Modification de date', 'date': '10/07/2024', 'status': 'Approuvé'},
  ];

  void _rechercher() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _showResult = true;
        _selectedReservation = _searchController.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Report / Modification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F056B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Recherche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rechercher une réservation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Référence, nom client...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF0F056B)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _rechercher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F056B),
                          foregroundColor: Colors.white,  // ← Blanc
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        child: const Text(
                          'RECHERCHER',
                          style: TextStyle(
                            color: Colors.white,  // ← Blanc
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Résultats
            if (_showResult)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _buildCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat de la recherche',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F056B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._reservations
                        .where((r) => r['id'].contains(_searchController.text) ||
                            r['client'].contains(_searchController.text))
                        .map((reservation) => _buildReservationItem(reservation))
                        .toList(),
                    if (_reservations
                        .where((r) => r['id'].contains(_searchController.text) ||
                            r['client'].contains(_searchController.text))
                        .isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Aucune réservation trouvée',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ✅ Modifications
            if (_showResult)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _buildCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F056B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionItem(
                      'Report de voyage',
                      Icons.calendar_today,
                      'Reporter à une autre date',
                      Colors.orange,
                    ),
                    _buildActionItem(
                      'Modification date',
                      Icons.date_range,
                      'Changer la date du voyage',
                      Colors.blue,
                    ),
                    _buildActionItem(
                      'Modification heure',
                      Icons.access_time,
                      'Changer l\'heure de départ',
                      Colors.green,
                    ),
                    _buildActionItem(
                      'Changement siège',
                      Icons.event_seat,
                      'Changer le numéro de siège',
                      Colors.purple,
                    ),
                    const SizedBox(height: 16),
                    
                    // Historique
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Historique des modifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_modifications.length} modifications',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._modifications.map((modif) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: modif['status'] == 'Approuvé'
                                        ? Colors.green
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    modif['action'],
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  modif['date'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: modif['status'] == 'Approuvé'
                                        ? Colors.green[100]
                                        : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    modif['status'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: modif['status'] == 'Approuvé'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
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
                Text(
                  reservation['id'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  reservation['client'],
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${reservation['trajet']} • ${reservation['date']} ${reservation['heure']} • Siège ${reservation['siege']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Modification en cours...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F056B),
              foregroundColor: Colors.white,  // ← Blanc
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'MODIFIER',
              style: TextStyle(
                color: Colors.white,  // ← Blanc
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, IconData icon, String description, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📝 ${label} en cours...'),
            backgroundColor: Colors.blue,
          ),
        );
      },
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