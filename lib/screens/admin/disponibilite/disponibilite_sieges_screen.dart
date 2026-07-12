import 'package:flutter/material.dart';

class DisponibiliteSiegesScreen extends StatefulWidget {
  const DisponibiliteSiegesScreen({super.key});

  @override
  _DisponibiliteSiegesScreenState createState() => _DisponibiliteSiegesScreenState();
}

class _DisponibiliteSiegesScreenState extends State<DisponibiliteSiegesScreen> {
  int _selectedBusIndex = 0;

  final List<Map<String, dynamic>> _buses = [
    {
      'id': 'BUS-001',
      'gare': 'Dakar',
      'heure': '08:00',
      'total': 37,
      'vendus': 22,
      'prestige': 5,
      'standard': 32,
      'places': List.generate(37, (i) => i < 22 ? 'occupe' : 'disponible'),
    },
    {
      'id': 'BUS-002',
      'gare': 'Thiès',
      'heure': '10:30',
      'total': 37,
      'vendus': 15,
      'prestige': 5,
      'standard': 32,
      'places': List.generate(37, (i) => i < 15 ? 'occupe' : 'disponible'),
    },
    {
      'id': 'BUS-003',
      'gare': 'Saint-Louis',
      'heure': '14:00',
      'total': 37,
      'vendus': 28,
      'prestige': 5,
      'standard': 32,
      'places': List.generate(37, (i) => i < 28 ? 'occupe' : 'disponible'),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bus = _buses[_selectedBusIndex];
    final placesDisponibles = bus['total'] - bus['vendus'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Disponibilité des Sièges'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F056B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Sélecteur de bus
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionner un bus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedBusIndex,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    items: _buses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bus = entry.value;
                      return DropdownMenuItem(
                        value: index,
                        child: Text('${bus['id']} - ${bus['gare']} ${bus['heure']}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedBusIndex = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Informations du bus
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus['id'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F056B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gare: ${bus['gare']} • Heure: ${bus['heure']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: placesDisponibles > 0 ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${bus['vendus']}/${bus['total']} places',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: placesDisponibles > 0 ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip('Prestige', '${bus['prestige']}', const Color(0xFFEFD807)),
                      const SizedBox(width: 8),
                      _buildInfoChip('Standard', '${bus['standard']}', Colors.blue),
                      const SizedBox(width: 8),
                      _buildInfoChip('Disponibles', '$placesDisponibles', Colors.green),
                      const SizedBox(width: 8),
                      _buildInfoChip('Vendus', '${bus['vendus']}', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Plan des sièges
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan des sièges',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSiegesGrid(bus['places']),
                  const SizedBox(height: 16),
                  _buildLegende(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSiegesGrid(List<String> places) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final statut = places[index];
        final Color color;
        final String label;
        
        if (statut == 'disponible') {
          color = Colors.green;
          label = '🟩';
        } else if (statut == 'occupe') {
          color = Colors.red;
          label = '🟥';
        } else {
          color = Colors.orange;
          label = '🟧';
        }

        // Simuler les places Prestige (1-5)
        final isPrestige = (index + 1) <= 5;

        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 1),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isPrestige ? const Color(0xFFEFD807) : color,
                  ),
                ),
                if (isPrestige)
                  const Icon(
                    Icons.stars,
                    size: 10,
                    color: Color(0xFFEFD807),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegende() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendeItem('🟩 Disponible', Colors.green),
        _buildLegendeItem('🟥 Occupé', Colors.red),
        _buildLegendeItem('🟧 Réservé', Colors.orange),
        _buildLegendeItem('⭐ Prestige', const Color(0xFFEFD807)),
      ],
    );
  }

  Widget _buildLegendeItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
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