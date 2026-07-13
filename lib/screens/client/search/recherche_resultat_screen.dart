import 'package:flutter/material.dart';
import 'package:catrans_app/models/catalog/catalog_search_criteria.dart';
import 'package:catrans_app/screens/client/booking/choix_place_economie_screen.dart';
import 'package:catrans_app/screens/client/booking/choix_place_prestige_screen.dart';

class RechercheResultatScreen extends StatefulWidget {
  final String depart;
  final String arrivee;
  final DateTime date;
  final String classe;
  final int nombrePassagers;
  final double prixUnitaire;
  final int points;
  final CatalogSearchCriteria? searchCriteria;

  const RechercheResultatScreen({
    super.key,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.classe,
    required this.nombrePassagers,
    required this.prixUnitaire,
    required this.points,
    this.searchCriteria,
  });

  @override
  _RechercheResultatScreenState createState() =>
      _RechercheResultatScreenState();
}

class _RechercheResultatScreenState extends State<RechercheResultatScreen> {
  List<Map<String, dynamic>> _trajets = [];
  List<Map<String, dynamic>> _filteredTrajets = [];
  bool _isLoading = true;
  String _selectedTri = 'Prix';
  List<DateTime> _datesAlternatives = [];
  DateTime? _selectedDateAlternative;

  @override
  void initState() {
    super.initState();
    _genererDatesAlternatives();
    _chargerTrajets();
  }

  void _genererDatesAlternatives() {
    _datesAlternatives = [
      widget.date,
      widget.date.add(const Duration(days: 1)),
      widget.date.add(const Duration(days: 2)),
      widget.date.add(const Duration(days: 3)),
      widget.date.add(const Duration(days: 4)),
      widget.date.add(const Duration(days: 5)),
    ];
    _selectedDateAlternative = widget.date;
  }

  void _chargerTrajets() {
    final seed = _selectedDateAlternative?.day ?? widget.date.day;

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _trajets = [
          {
            'heure': '08:00',
            'prix': widget.prixUnitaire,
            'places': 12 - (seed % 8),
            'duree': '2h30',
            'date': _selectedDateAlternative,
          },
          {
            'heure': '10:00',
            'prix': widget.prixUnitaire + 300,
            'places': 8 - (seed % 6),
            'duree': '2h30',
            'date': _selectedDateAlternative?.add(const Duration(hours: 2)),
          },
          {
            'heure': '12:00',
            'prix': widget.prixUnitaire + 200,
            'places': 5 - (seed % 4),
            'duree': '2h45',
            'date': _selectedDateAlternative?.add(const Duration(hours: 4)),
          },
          {
            'heure': '09:00',
            'prix': widget.prixUnitaire + 500,
            'places': 3 - (seed % 3),
            'duree': '2h15',
            'date': _selectedDateAlternative?.add(const Duration(hours: 1)),
          },
          {
            'heure': '11:00',
            'prix': widget.prixUnitaire + 100,
            'places': 15 - (seed % 10),
            'duree': '3h00',
            'date': _selectedDateAlternative?.add(const Duration(hours: 3)),
          },
        ];
        _filteredTrajets = List.from(_trajets);
        _isLoading = false;
        _appliquerTri();
      });
    });
  }

  void _appliquerTri() {
    List<Map<String, dynamic>> resultats = List.from(_trajets);
    if (_selectedTri == 'Prix') {
      resultats.sort((a, b) => a['prix'].compareTo(b['prix']));
    } else if (_selectedTri == 'Prix décroissant') {
      resultats.sort((a, b) => b['prix'].compareTo(a['prix']));
    } else if (_selectedTri == 'Heure') {
      resultats.sort((a, b) => a['heure'].compareTo(b['heure']));
    } else if (_selectedTri == 'Durée') {
      resultats.sort((a, b) => a['duree'].compareTo(b['duree']));
    }
    setState(() => _filteredTrajets = resultats);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPrestige = widget.classe == 'prestige';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPrestige ? const Color(0xFFEFD807) : Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.classe.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPrestige ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.depart} → ${widget.arrivee}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(_selectedDateAlternative ?? widget.date),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _chargerTrajets();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Mise à jour: ${_formatDate(DateTime.now())}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  '${_filteredTrajets.length} trajets',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F056B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Autres dates disponibles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _datesAlternatives.length,
                    itemBuilder: (context, index) {
                      final date = _datesAlternatives[index];
                      final isSelected = date == _selectedDateAlternative;
                      final isToday = date.day == DateTime.now().day &&
                          date.month == DateTime.now().month;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDateAlternative = date;
                            _isLoading = true;
                          });
                          _chargerTrajets();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0F056B)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0F056B)
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Aujourd\'hui',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Text(
                                _formatDateShort(date),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0F056B)),
                        SizedBox(height: 20),
                        Text('Recherche des trajets...',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  )
                : _filteredTrajets.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bus,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 20),
                            Text('Aucun trajet trouvé',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            Text('Essayez de modifier votre recherche',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTrajets.length,
                        itemBuilder: (context, index) {
                          final trajet = _filteredTrajets[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'CA TRANS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF0F056B),
                                        ),
                                      ),
                                      if (isPrestige)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.event_seat,
                                                  size: 14,
                                                  color: Colors.green),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${trajet['places']} places',
                                                style: TextStyle(
                                                  color: Colors.green[800],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 20, color: Color(0xFF0F056B)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Départ à ${trajet['heure']}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          trajet['duree'],
                                          style: TextStyle(
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Prix',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                          Text(
                                            '${trajet['prix'].toStringAsFixed(0)} FCFA',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F056B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (widget.classe == 'economie') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChoixPlaceEconomieScreen(
                                                  depart: widget.depart,
                                                  arrivee: widget.arrivee,
                                                  date:
                                                      _selectedDateAlternative ??
                                                          widget.date,
                                                  heure: trajet['heure'],
                                                  prix: trajet['prix'],
                                                  nombrePassagers:
                                                      widget.nombrePassagers,
                                                  points: widget.points,
                                                ),
                                              ),
                                            );
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChoixPlacePrestigeScreen(
                                                  depart: widget.depart,
                                                  arrivee: widget.arrivee,
                                                  date:
                                                      _selectedDateAlternative ??
                                                          widget.date,
                                                  heure: trajet['heure'],
                                                  prix: trajet['prix'],
                                                  nombrePassagers:
                                                      widget.nombrePassagers,
                                                  points: widget.points,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFEFD807),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          minimumSize: const Size(120, 40),
                                        ),
                                        child: const Text(
                                          'RÉSERVER',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSortBottomSheet(context),
                    icon: const Icon(Icons.sort, color: Colors.white),
                    label: const Text(
                      'Trier',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F056B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    final List<String> options = ['Prix', 'Prix décroissant', 'Heure', 'Durée'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trier par',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F056B),
                ),
              ),
              const Divider(),
              ...options.map((option) {
                return ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontWeight: _selectedTri == option
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedTri == option
                          ? const Color(0xFF0F056B)
                          : Colors.black,
                    ),
                  ),
                  trailing: _selectedTri == option
                      ? const Icon(Icons.check, color: Color(0xFF0F056B))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedTri = option;
                      _appliquerTri();
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
