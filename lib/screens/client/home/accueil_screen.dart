import 'package:flutter/material.dart';
import 'package:catrans_app/widgets/client/bottom_nav_bar.dart';
import 'package:catrans_app/widgets/client/trajet_populaire.dart';
import 'package:catrans_app/widgets/client/hero_promo.dart';
import 'package:catrans_app/screens/client/search/choix_classe_screen.dart';
import 'package:catrans_app/screens/client/tickets/mes_reservations_screen.dart';
import 'package:catrans_app/screens/client/profile/profil_screen.dart';
import 'package:catrans_app/screens/client/profile/points_fidelite_screen.dart';
import 'package:catrans_app/screens/client/support/support_screen.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  _AccueilScreenState createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  int _selectedIndex = 0;
  String? _selectedDepart;
  String? _selectedArrivee;
  DateTime _selectedDate = DateTime.now();
  
  late PageController _pageController;
  int _currentPage = 0;

  final List<String> _villes = [
    'Dakar',
    'Thiès',
    'Saint-Louis',
    'Mbour',
    'Kaolack',
    'Ziguinchor',
    'Touba',
    'Diourbel',
    'Louga',
    'Tambacounda',
  ];

  final List<Map<String, dynamic>> _promotions = [
    {'title': 'Promotion Été', 'subtitle': '-20% sur tous les trajets'},
    {'title': 'Offre Famille', 'subtitle': 'Achetez 3 billets, le 4ème gratuit'},
    {'title': 'Student Discount', 'subtitle': '10% pour les étudiants'},
  ];

  final List<Map<String, dynamic>> _trajetsPopulaires = [
    {'depart': 'Dakar', 'arrivee': 'Thiès', 'prix': 1500, 'duree': '1h30'},
    {'depart': 'Dakar', 'arrivee': 'Saint-Louis', 'prix': 3500, 'duree': '3h'},
    {'depart': 'Thiès', 'arrivee': 'Mbour', 'prix': 2000, 'duree': '2h'},
    {'depart': 'Dakar', 'arrivee': 'Kaolack', 'prix': 4000, 'duree': '3h30'},
    {'depart': 'Dakar', 'arrivee': 'Ziguinchor', 'prix': 8000, 'duree': '6h'},
  ];

  bool _showAllTrajets = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _autoScroll() {
    if (_pageController.hasClients) {
      final nextPage = (_currentPage + 1) % _promotions.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
  }

  void _permuterVilles() {
    setState(() {
      final temp = _selectedDepart;
      _selectedDepart = _selectedArrivee;
      _selectedArrivee = temp;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Mes billets
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MesReservationsScreen()),
      ).then((_) {
        setState(() => _selectedIndex = 0);
      });
    } else if (index == 2) {
      // Support
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SupportScreen()),
      ).then((_) {
        setState(() => _selectedIndex = 0);
      });
    } else if (index == 3) {
      // Profil
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilScreen()),
      ).then((_) {
        setState(() => _selectedIndex = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final prenom = user?.firstname ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prenom.isNotEmpty ? 'Bonjour $prenom 👋' : 'Bonjour 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F056B),
                        ),
                      ),
                      const Text(
                        'Où souhaitez-vous aller ?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 30,
                          color: Color(0xFF0F056B),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Aucune notification pour le moment'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Formulaire de recherche
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Départ
                    DropdownButtonFormField<String>(
                      value: _selectedDepart,
                      decoration: const InputDecoration(
                        labelText: 'Départ',
                        prefixIcon: Icon(Icons.location_on, color: Color(0xFF0F056B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: _villes.map((ville) {
                        return DropdownMenuItem<String>(
                          value: ville,
                          child: Text(ville),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepart = value;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    // Bouton permuter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.swap_vert,
                            color: Color(0xFF0F056B),
                            size: 30,
                          ),
                          onPressed: _permuterVilles,
                          tooltip: 'Permuter départ et arrivée',
                        ),
                      ],
                    ),

                    // Arrivée
                    DropdownButtonFormField<String>(
                      value: _selectedArrivee,
                      decoration: const InputDecoration(
                        labelText: 'Arrivée',
                        prefixIcon: Icon(Icons.flag, color: Color(0xFF0F056B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: _villes.map((ville) {
                        return DropdownMenuItem<String>(
                          value: ville,
                          child: Text(ville),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedArrivee = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // Date
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de départ',
                          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0F056B)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        child: Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Bouton RECHERCHER
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedDepart != null && _selectedArrivee != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChoixClasseScreen(
                                  depart: _selectedDepart!,
                                  arrivee: _selectedArrivee!,
                                  date: _selectedDate,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez sélectionner un départ et une arrivée'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFD807),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'RECHERCHER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Promotions
              const Text(
                'Promotions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F056B),
                ),
              ),
              const SizedBox(height: 15),

              // HeroPromo
              const HeroPromo(),

              const SizedBox(height: 30),

              // Trajets populaires
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trajets populaires',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllTrajets = !_showAllTrajets;
                      });
                    },
                    child: Text(
                      _showAllTrajets ? 'VOIR MOINS' : 'VOIR TOUT',
                      style: TextStyle(
                        color: const Color(0xFF0F056B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Liste des trajets populaires
              Column(
                children: (_showAllTrajets ? _trajetsPopulaires : _trajetsPopulaires.take(3).toList())
                    .map((trajet) => TrajetPopulaire(
                          depart: trajet['depart'] as String,
                          arrivee: trajet['arrivee'] as String,
                          prix: (trajet['prix'] as num).toDouble(),
                          duree: trajet['duree'] as String,
                        ))
                    .toList(),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}