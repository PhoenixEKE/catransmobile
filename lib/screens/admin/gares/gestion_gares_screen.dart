import 'package:flutter/material.dart';
import 'package:catrans_app/models/transport/station.dart';
import 'package:catrans_app/models/transport/company.dart';
import 'package:catrans_app/models/transport/city.dart';

class GestionGaresScreen extends StatefulWidget {
  const GestionGaresScreen({super.key});

  @override
  _GestionGaresScreenState createState() => _GestionGaresScreenState();
}

class _GestionGaresScreenState extends State<GestionGaresScreen> {
  List<Station> _gares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerGares();
  }

  void _chargerGares() {
    Future.delayed(const Duration(seconds: 1), () {
      final company = Company(
        id: '1',
        name: 'CA TRANS',
        code: 'CAT',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final city = City(
        id: '1',
        name: 'Dakar',
        normalizedName: 'dakar',
        country: 'Sénégal',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _gares = [
          Station(
            id: '1',
            company: company,
            city: city,
            name: 'Gare Principale',
            normalizedName: 'gare_principale',
            cityNameSnapshot: 'Dakar',
            phoneLine: '+221 33 123 45 67',
            representative: 'M. Diop',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Station(
            id: '2',
            company: company,
            city: City(
              id: '2',
              name: 'Thiès',
              normalizedName: 'thies',
              country: 'Sénégal',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            name: 'Gare de Thiès',
            normalizedName: 'gare_thies',
            cityNameSnapshot: 'Thiès',
            phoneLine: '+221 33 123 45 68',
            representative: 'Mme Fall',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Station(
            id: '3',
            company: company,
            city: City(
              id: '3',
              name: 'Saint-Louis',
              normalizedName: 'saint_louis',
              country: 'Sénégal',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            name: 'Gare de Saint-Louis',
            normalizedName: 'gare_saint_louis',
            cityNameSnapshot: 'Saint-Louis',
            phoneLine: '+221 33 123 45 69',
            representative: 'M. Ndiaye',
            isActive: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        _isLoading = false;
      });
    });
  }

  void _ajouterGare() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une gare'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nom de la gare',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
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
              // Ajouter la gare
              final company = Company(
                id: '1',
                name: 'CA TRANS',
                code: 'CAT',
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              setState(() {
                _gares.add(Station(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  company: company,
                  name: 'Nouvelle Gare',
                  normalizedName: 'nouvelle_gare',
                  cityNameSnapshot: 'Nouvelle Ville',
                  phoneLine: '+221 00 000 00 00',
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gare ajoutée avec succès')),
              );
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

  void _modifierGare(Station gare) {
    final nomController = TextEditingController(text: gare.name);
    final villeController = TextEditingController(text: gare.cityNameSnapshot ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la gare'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la gare',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: villeController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
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
              setState(() {
                // Modifier la gare (simulé)
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gare modifiée avec succès')),
              );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestion des Gares'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F056B),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0F056B)),
            onPressed: _ajouterGare,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F056B)),
            onPressed: _chargerGares,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _gares.length,
              itemBuilder: (context, index) {
                final gare = _gares[index];
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
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: gare.isActive ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_city,
                            color: gare.isActive ? Colors.green : Colors.red,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gare.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gare.city?.name ?? gare.cityNameSnapshot ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 12, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    gare.phoneLine ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gare.isActive
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      gare.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: gare.isActive
                                            ? Colors.green                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _modifierGare(gare),
                            ),
                            IconButton(
                              icon: Icon(
                                gare.isActive ? Icons.pause : Icons.play_arrow,
                                color: gare.isActive ? Colors.orange : Colors.green,
                              ),
                              onPressed: () {
                                // Activer/Désactiver
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}