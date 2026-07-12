import 'package:flutter/material.dart';
import 'package:catrans_app/models/transport/route.dart' as model;
import 'package:catrans_app/models/transport/company.dart';
import 'package:catrans_app/models/transport/station.dart';

class GestionLignesScreen extends StatefulWidget {
  const GestionLignesScreen({super.key});

  @override
  _GestionLignesScreenState createState() => _GestionLignesScreenState();
}

class _GestionLignesScreenState extends State<GestionLignesScreen> {
  List<model.Route> _lignes = [];
  bool _isLoading = true;
  final TextEditingController _departController = TextEditingController();
  final TextEditingController _arriveeController = TextEditingController();

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
    _chargerLignes();
  }

  void _chargerLignes() {
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
        _lignes = [
          model.Route(
            id: '1',
            company: _company,
            departureStation: station,
            destinationNameSnapshot: 'Thiès',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          model.Route(
            id: '2',
            company: _company,
            departureStation: station,
            destinationNameSnapshot: 'Saint-Louis',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          model.Route(
            id: '3',
            company: _company,
            departureStation: stationThies,
            destinationNameSnapshot: 'Mbour',
            isActive: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        _isLoading = false;
      });
    });
  }

  // ✅ AJOUTER UNE LIGNE
  void _ajouterLigne() {
    _departController.clear();
    _arriveeController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une ligne'),
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
              if (_departController.text.isNotEmpty && _arriveeController.text.isNotEmpty) {
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
                  _lignes.add(model.Route(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    company: _company,
                    departureStation: station,
                    destinationNameSnapshot: _arriveeController.text,
                    isActive: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Ligne ajoutée avec succès'),
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

  // ✅ MODIFIER UNE LIGNE
  void _modifierLigne(model.Route ligne) {
    _departController.text = ligne.departureStation.name;
    _arriveeController.text = ligne.destinationNameSnapshot;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la ligne'),
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
              if (_departController.text.isNotEmpty && _arriveeController.text.isNotEmpty) {
                // Modifier la ligne (simulé)
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Ligne modifiée avec succès'),
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

  // ✅ SUPPRIMER UNE LIGNE
  void _supprimerLigne(model.Route ligne, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la ligne'),
        content: Text(
          'Voulez-vous vraiment supprimer la ligne '
          '${ligne.departureStation.name} → ${ligne.destinationNameSnapshot} ?',
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
                _lignes.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Ligne supprimée'),
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

  // ✅ ACTIVER/DÉSACTIVER UNE LIGNE
  void _toggleLigne(model.Route ligne) {
    setState(() {
      // Modification de l'état (simulé car isActive est final)
      // Dans un cas réel, on appellerait une API
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ligne.isActive 
              ? '⏸️ Ligne désactivée' 
              : '▶️ Ligne activée',
        ),
        backgroundColor: ligne.isActive ? Colors.orange : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestion des Lignes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F056B),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0F056B)),
            onPressed: _ajouterLigne,
            tooltip: 'Ajouter une ligne',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F056B)),
            onPressed: _chargerLignes,
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
                  Text('Chargement des lignes...'),
                ],
              ),
            )
          : _lignes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Aucune ligne disponible',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Cliquez sur le bouton + pour ajouter une ligne',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lignes.length,
                  itemBuilder: (context, index) {
                    final ligne = _lignes[index];
                    final isActive = ligne.isActive;
                    final color = isActive ? Colors.blue : Colors.red;

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
                                Icons.route,
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
                                    '${ligne.departureStation.name} → ${ligne.destinationNameSnapshot}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
                                          isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Compagnie: ${ligne.company.name}',
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
                                  onPressed: () => _modifierLigne(ligne),
                                  tooltip: 'Modifier',
                                ),
                                
                                // Bouton Activer/Désactiver
                                IconButton(
                                  icon: Icon(
                                    isActive ? Icons.pause : Icons.play_arrow,
                                    color: isActive ? Colors.orange : Colors.green,
                                  ),
                                  onPressed: () => _toggleLigne(ligne),
                                  tooltip: isActive ? 'Désactiver' : 'Activer',
                                ),
                                
                                // Bouton Supprimer
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _supprimerLigne(ligne, index),
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
      // ✅ Bouton flottant pour ajouter rapidement
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterLigne,
        backgroundColor: const Color(0xFF0F056B),
        foregroundColor: Colors.white,
        tooltip: 'Ajouter une ligne',
        child: const Icon(Icons.add),
      ),
    );
  }
}