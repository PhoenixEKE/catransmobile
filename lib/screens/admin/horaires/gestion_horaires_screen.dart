import 'package:flutter/material.dart';
import 'package:catrans_app/models/transport/schedule.dart';
import 'package:catrans_app/models/transport/station.dart';
import 'package:catrans_app/models/transport/company.dart';

class GestionHorairesScreen extends StatefulWidget {
  const GestionHorairesScreen({super.key});

  @override
  _GestionHorairesScreenState createState() => _GestionHorairesScreenState();
}

class _GestionHorairesScreenState extends State<GestionHorairesScreen> {
  List<Schedule> _horaires = [];
  bool _isLoading = true;
  
  // Contrôleurs pour l'ajout
  final TextEditingController _departController = TextEditingController();
  final TextEditingController _arriveeController = TextEditingController();
  final TextEditingController _heureController = TextEditingController();
  final TextEditingController _busController = TextEditingController();
  
  // Compagnie par défaut
  late Company _company;

  @override
  void initState() {
    super.initState();
    _company = Company(
      id: '1',
      name: 'CA TRANS',
      code: 'CAT',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _chargerHoraires();
  }

  void _chargerHoraires() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      final station = Station(
        id: '1',
        company: _company,
        name: 'Gare Principale',
        normalizedName: 'gare_principale',
        cityNameSnapshot: 'Dakar',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final stationThies = Station(
        id: '2',
        company: _company,
        name: 'Gare de Thiès',
        normalizedName: 'gare_thies',
        cityNameSnapshot: 'Thiès',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _horaires = [
          Schedule(
            id: '1',
            station: station,
            departureTimeRaw: '08:00',
            departureTime: DateTime.now().add(const Duration(hours: 2)),
            routeNote: 'Dakar → Thiès',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Schedule(
            id: '2',
            station: station,
            departureTimeRaw: '10:30',
            departureTime: DateTime.now().add(const Duration(hours: 4)),
            routeNote: 'Dakar → Saint-Louis',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Schedule(
            id: '3',
            station: stationThies,
            departureTimeRaw: '14:00',
            departureTime: DateTime.now().add(const Duration(hours: 6)),
            routeNote: 'Thiès → Mbour',
            isActive: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        _isLoading = false;
      });
    });
  }

  void _ajouterHoraire() {
    _departController.clear();
    _arriveeController.clear();
    _heureController.clear();
    _busController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un horaire'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _departController,
                decoration: const InputDecoration(
                  labelText: 'Départ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _arriveeController,
                decoration: const InputDecoration(
                  labelText: 'Arrivée',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _heureController,
                decoration: const InputDecoration(
                  labelText: 'Heure (HH:MM)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _busController,
                decoration: const InputDecoration(
                  labelText: 'Bus',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_bus),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_departController.text.isNotEmpty &&
                  _arriveeController.text.isNotEmpty &&
                  _heureController.text.isNotEmpty &&
                  _busController.text.isNotEmpty) {
                
                final station = Station(
                  id: 'station_${DateTime.now().millisecondsSinceEpoch}',
                  company: _company,
                  name: _departController.text,
                  normalizedName: _departController.text.toLowerCase(),
                  cityNameSnapshot: _departController.text,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                setState(() {
                  _horaires.add(Schedule(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    station: station,
                    departureTimeRaw: _heureController.text,
                    departureTime: DateTime.now(),
                    routeNote: '${_departController.text} → ${_arriveeController.text}',
                    isActive: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Horaire ajouté avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F056B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _modifierHoraire(Schedule horaire) {
    _departController.text = horaire.station.name;
    _arriveeController.text = horaire.routeNote?.replaceAll('${horaire.station.name} → ', '') ?? '';
    _heureController.text = horaire.departureTimeRaw;
    _busController.text = 'BUS-00${_horaires.indexOf(horaire) + 1}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'horaire'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _departController,
                decoration: const InputDecoration(
                  labelText: 'Départ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _arriveeController,
                decoration: const InputDecoration(
                  labelText: 'Arrivée',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _heureController,
                decoration: const InputDecoration(
                  labelText: 'Heure (HH:MM)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _busController,
                decoration: const InputDecoration(
                  labelText: 'Bus',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_bus),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_departController.text.isNotEmpty &&
                  _arriveeController.text.isNotEmpty &&
                  _heureController.text.isNotEmpty &&
                  _busController.text.isNotEmpty) {
                
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Horaire modifié avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F056B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _supprimerHoraire(Schedule horaire, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'horaire'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'horaire de ${horaire.departureTimeRaw} '
          'pour ${horaire.station.name} ?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _horaires.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Horaire supprimé'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleHoraire(Schedule horaire) {
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          horaire.isActive 
              ? '⏸️ Horaire suspendu' 
              : '▶️ Horaire activé',
        ),
        backgroundColor: horaire.isActive ? Colors.orange : Colors.green,
      ),
    );
  }

  void _suspendreHoraire(Schedule horaire) {
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏸️ Départ suspendu'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestion des Horaires'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F056B),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0F056B)),
            onPressed: _ajouterHoraire,
            tooltip: 'Ajouter un horaire',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F056B)),
            onPressed: _chargerHoraires,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F056B)),
                  SizedBox(height: 20),
                  Text('Chargement des horaires...'),
                ],
              ),
            )
          : _horaires.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Aucun horaire disponible',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Cliquez sur le bouton + pour ajouter un horaire',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _horaires.length,
                  itemBuilder: (context, index) {
                    final horaire = _horaires[index];
                    final isActive = horaire.isActive;
                    final color = isActive ? Colors.blue : Colors.red;
                    final statutColor = isActive ? Colors.blue : Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icône
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: color,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Informations
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Départ: ${horaire.departureTimeRaw}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    horaire.station.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isActive ? 'Actif' : 'Inactif',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (horaire.routeNote != null && horaire.routeNote!.isNotEmpty)
                                        Text(
                                          horaire.routeNote!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Bus: BUS-${(index + 1).toString().padLeft(3, '0')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bouton Modifier
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _modifierHoraire(horaire),
                                  tooltip: 'Modifier',
                                ),
                                
                                // Bouton Suspendre/Activer
                                IconButton(
                                  icon: Icon(
                                    isActive ? Icons.pause : Icons.play_arrow,
                                    color: isActive ? Colors.orange : Colors.green,
                                  ),
                                  onPressed: () => _toggleHoraire(horaire),
                                  tooltip: isActive ? 'Suspendre' : 'Activer',
                                ),
                                
                                // Bouton Supprimer
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _supprimerHoraire(horaire, index),
                                  tooltip: 'Supprimer',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterHoraire,
        backgroundColor: const Color(0xFF0F056B),
        foregroundColor: Colors.white,
        tooltip: 'Ajouter un horaire',
        child: const Icon(Icons.add),
      ),
    );
  }
}