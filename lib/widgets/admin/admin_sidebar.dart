import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.dashboard, 'label': 'Tableau de bord'},
    {'icon': Icons.location_city, 'label': 'Gares'},
    {'icon': Icons.route, 'label': 'Lignes'},
    {'icon': Icons.access_time, 'label': 'Horaires'},
    {'icon': Icons.attach_money, 'label': 'Tarifs'},
    {'icon': Icons.event_seat, 'label': 'Sièges'},
    {'icon': Icons.storefront, 'label': 'Portail Gare'},
    {'icon': Icons.edit_document, 'label': 'Report/Modif'},
    {'icon': Icons.airline_seat_recline_normal, 'label': 'Disponibilité'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF0F056B),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/icons/logo.png',
                  height: 40,
                  width: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.directions_bus, color: Colors.white, size: 30);
                  },
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'CITRANS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    item['icon'],
                    color: isSelected ? const Color(0xFFEFD807) : Colors.white54,
                    size: 22,
                  ),
                  title: Text(
                    item['label'],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFEFD807) : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.white.withOpacity(0.1),
                  onTap: () => onItemTapped(index),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'v1.0.0',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}