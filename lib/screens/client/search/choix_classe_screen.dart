import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/models/catalog/catalog_search_criteria.dart';
import 'package:catrans_app/screens/client/search/recherche_resultat_screen.dart';

class ChoixClasseScreen extends StatefulWidget {
  final String depart;
  final String arrivee;
  final DateTime date;
  final CatalogSearchCriteria? searchCriteria;

  const ChoixClasseScreen({
    super.key,
    required this.depart,
    required this.arrivee,
    required this.date,
    this.searchCriteria,
  });

  @override
  _ChoixClasseScreenState createState() => _ChoixClasseScreenState();
}

class _ChoixClasseScreenState extends State<ChoixClasseScreen> {
  String _selectedClasse = 'economie';
  int _nombrePassagers = 1;

  static const Map<String, double> _prixParClasse = {
    'economie': 7000,
    'prestige': 8000,
  };

  static const Map<String, int> _pointsParClasse = {
    'economie': 5,
    'prestige': 10,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Choisissez votre classe'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.depart} → ${widget.arrivee}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F056B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Compagnie: CA TRANS',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFD807),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nombre de passagers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_nombrePassagers > 1) {
                            setState(() => _nombrePassagers--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: _nombrePassagers > 1 ? Colors.blue : Colors.grey,
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$_nombrePassagers',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _nombrePassagers++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildClasseCard(
              titre: 'ÉCONOMIE',
              code: 'economie',
              points: _pointsParClasse['economie']!,
              description: 'Voyage confortable à petit prix',
              avantages: [
                'Attribution des places à la gare',
                'Accès aux toilettes',
                '+5 points de fidélité par billet',
              ],
              couleur: Colors.blue,
              isSelected: _selectedClasse == 'economie',
              onTap: () => setState(() => _selectedClasse = 'economie'),
            ),
            const SizedBox(height: 16),
            _buildClasseCard(
              titre: 'PRESTIGE',
              code: 'prestige',
              points: _pointsParClasse['prestige']!,
              description: 'Voyage premium avec services exclusifs',
              avantages: [
                'Choix de siège sur plan interactif',
                'Collation incluse',
                'Toilettes privées',
                'Sans escale',
                '+10 points de fidélité par billet',
              ],
              couleur: const Color(0xFFEFD807),
              isSelected: _selectedClasse == 'prestige',
              onTap: () => setState(() => _selectedClasse = 'prestige'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    RoutePaths.rechercheResultat,
                    extra: RechercheResultatScreen(
                      depart: widget.depart,
                      arrivee: widget.arrivee,
                      date: widget.date,
                      classe: _selectedClasse,
                      nombrePassagers: _nombrePassagers,
                      prixUnitaire: _prixParClasse[_selectedClasse]!,
                      points: _pointsParClasse[_selectedClasse]!,
                      searchCriteria: widget.searchCriteria,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFD807),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CONTINUER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedClasse == 'economie'
                          ? 'Les places seront attribuées à la gare par nos agents selon disponibilité'
                          : 'Choisissez vos places sur le plan interactif',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
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

  Widget _buildClasseCard({
    required String titre,
    required String code,
    required int points,
    required String description,
    required List<String> avantages,
    required Color couleur,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? couleur.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? couleur : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: couleur.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? couleur : Colors.black87,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'SÉLECTIONNÉ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Prix affiché à l’étape suivante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: couleur,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFD807).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars,
                          size: 12, color: Color(0xFFEFD807)),
                      const SizedBox(width: 4),
                      Text(
                        '+$points pts/billet',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEFD807),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...avantages.map((avantage) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: couleur, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          avantage,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tarif final',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Selon le départ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: couleur,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
