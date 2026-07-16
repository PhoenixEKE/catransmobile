import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:catrans_app/screens/admin/gares/gestion_gares_screen.dart';
import 'package:catrans_app/screens/admin/lignes/gestion_lignes_screen.dart';
import 'package:catrans_app/screens/admin/horaires/gestion_horaires_screen.dart';
import 'package:catrans_app/screens/admin/tarifs/gestion_tarifs_screen.dart';
import 'package:catrans_app/screens/admin/sieges/gestion_sieges_screen.dart';
import 'package:catrans_app/screens/admin/gares/gare_dashboard_screen.dart';
import 'package:catrans_app/screens/admin/report/report_modification_screen.dart';
import 'package:catrans_app/screens/admin/disponibilite/disponibilite_sieges_screen.dart';
import 'package:catrans_app/widgets/admin/admin_sidebar.dart';
import 'package:catrans_app/widgets/admin/admin_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardContent(),
    const GestionGaresScreen(),
    const GestionLignesScreen(),
    const GestionHorairesScreen(),
    const GestionTarifsScreen(),
    const GestionSiegesScreen(),
    const GareDashboardScreen(),
    const ReportModificationScreen(),
    const DisponibiliteSiegesScreen(),
  ];

  final List<String> _titles = [
    'Tableau de bord',
    'Gestion des gares',
    'Gestion des lignes',
    'Gestion des horaires',
    'Gestion des tarifs',
    'Gestion des sièges',
    'Portail Gare',
    'Report / Modification',
    'Disponibilité des sièges',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemTapped: (index) => setState(() => _selectedIndex = index),
          ),
          Expanded(
            child: Column(
              children: [
                // AppBar avec déconnexion
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _titles[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F056B),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                          // ✅ Bouton Déconnexion Admin
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Déconnexion'),
                                  content: const Text(
                                      'Voulez-vous vraiment vous déconnecter ?'),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await context
                                            .read<AuthService>()
                                            .logout();
                                        if (!context.mounted) return;
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SplashScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Déconnecter'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF0F056B),
                            child: Text(
                              'A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Administrateur',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AdminCard(
                  title: 'Total Gares',
                  value: '12',
                  icon: Icons.location_city,
                  color: Colors.blue,
                  change: '+2',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminCard(
                  title: 'Lignes Actives',
                  value: '8',
                  icon: Icons.route,
                  color: Colors.green,
                  change: '+1',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminCard(
                  title: 'Trajets Aujourd\'hui',
                  value: '24',
                  icon: Icons.directions_bus,
                  color: Colors.orange,
                  change: '+5',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminCard(
                  title: 'Billets Vendus',
                  value: '1,247',
                  icon: Icons.airplane_ticket,
                  color: Colors.purple,
                  change: '+12%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activité récente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildActivityItem(
                  Icons.add_location,
                  Colors.green,
                  'Nouvelle gare ajoutée',
                  'Gare de Tambacounda',
                  'Il y a 5 min',
                ),
                _buildActivityItem(
                  Icons.edit_road,
                  Colors.blue,
                  'Ligne modifiée',
                  'Dakar → Saint-Louis',
                  'Il y a 1h',
                ),
                _buildActivityItem(
                  Icons.payment,
                  Colors.orange,
                  'Nouveau paiement',
                  'Orange Money - 3 500 FCFA',
                  'Il y a 2h',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
