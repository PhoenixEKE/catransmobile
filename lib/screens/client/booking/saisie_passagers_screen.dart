import 'package:flutter/material.dart';
import 'package:catrans_app/models/trajet.dart';
import 'package:catrans_app/screens/client/booking/choix_place_economie_screen.dart';
import 'package:catrans_app/screens/client/booking/choix_place_prestige_screen.dart';

class SaisiePassagersScreen extends StatefulWidget {
  final Trajet trajet;
  final String classe;

  const SaisiePassagersScreen({
    super.key,
    required this.trajet,
    required this.classe,
  });

  @override
  _SaisiePassagersScreenState createState() => _SaisiePassagersScreenState();
}

class _SaisiePassagersScreenState extends State<SaisiePassagersScreen> {
  final List<Map<String, TextEditingController>> _passagers = [];
  int _nombrePassagers = 1;

  @override
  void initState() {
    super.initState();
    _ajouterPassager();
  }

  void _ajouterPassager() {
    setState(() {
      _passagers.add({
        'nom': TextEditingController(),
        'prenom': TextEditingController(),
      });
      _nombrePassagers++;
    });
  }

  void _supprimerPassager(int index) {
    if (_passagers.length > 1) {
      setState(() {
        _passagers[index]['nom']?.dispose();
        _passagers[index]['prenom']?.dispose();
        _passagers.removeAt(index);
        _nombrePassagers--;
      });
    }
  }

  @override
  void dispose() {
    for (var passager in _passagers) {
      passager['nom']?.dispose();
      passager['prenom']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prixUnitaire = widget.classe == 'prestige' ? 8000 : 7000;
    final points = widget.classe == 'prestige' ? 10 : 5;
    final total = prixUnitaire * _passagers.length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Passagers (${widget.classe.toUpperCase()})'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Information sur les prix
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prix unitaire',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '$prixUnitaire FCFA',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F056B),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Points par billet',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.stars, color: Color(0xFFEFD807), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '+$points pts',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEFD807),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Liste des passagers
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _passagers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Passager ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_passagers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _supprimerPassager(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _passagers[index]['prenom'],
                                decoration: const InputDecoration(
                                  labelText: 'Prénom',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _passagers[index]['nom'],
                                decoration: const InputDecoration(
                                  labelText: 'Nom',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

            // Bouton Ajouter
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _ajouterPassager,
                icon: const Icon(Icons.add),
                label: const Text('AJOUTER UN PASSAGER'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Récapitulatif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F056B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0F056B).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nombre de passagers',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${_passagers.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$total FCFA',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F056B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Points gagnés',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.stars, color: Color(0xFFEFD807), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '+${points * _passagers.length} pts',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEFD807),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bouton Continuer vers le choix des places
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Vérifier que tous les passagers ont un nom et prénom
                  bool allFilled = true;
                  for (var passager in _passagers) {
                    if (passager['nom']?.text.trim().isEmpty ?? true) {
                      allFilled = false;
                      break;
                    }
                    if (passager['prenom']?.text.trim().isEmpty ?? true) {
                      allFilled = false;
                      break;
                    }
                  }

                  if (!allFilled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez remplir tous les champs'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  if (widget.classe == 'prestige') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChoixPlacePrestigeScreen(
                          depart: widget.trajet.depart,
                          arrivee: widget.trajet.arrivee,
                          date: widget.trajet.date,
                          heure: widget.trajet.heure,
                          prix: prixUnitaire.toDouble(),
                          nombrePassagers: _passagers.length,
                          points: points,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChoixPlaceEconomieScreen(
                          depart: widget.trajet.depart,
                          arrivee: widget.trajet.arrivee,
                          date: widget.trajet.date,
                          heure: widget.trajet.heure,
                          prix: prixUnitaire.toDouble(),
                          nombrePassagers: _passagers.length,
                          points: points,
                        ),
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
                  'CHOISIR LES PLACES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}