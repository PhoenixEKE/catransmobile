import 'package:flutter/material.dart';
import 'package:catrans_app/screens/client/booking/recapitulatif_screen.dart';

class ChoixPlaceScreen extends StatefulWidget {
  final String depart;
  final String arrivee;
  final DateTime date;
  final String heure;
  final double prix;
  final int nombrePassagers;
  final int points;
  final String classe;

  const ChoixPlaceScreen({
    super.key,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.heure,
    required this.prix,
    required this.nombrePassagers,
    required this.points,
    required this.classe,
  });

  @override
  _ChoixPlaceScreenState createState() => _ChoixPlaceScreenState();
}

class _ChoixPlaceScreenState extends State<ChoixPlaceScreen> {
  List<int> _placesSelectionnees = [];
  final List<int> _placesOccupees = [3, 7, 12, 18, 22, 29, 31];
  final List<TextEditingController> _nomControllers = [];
  final List<TextEditingController> _prenomControllers = [];
  int _passagerEnCours = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.nombrePassagers; i++) {
      _nomControllers.add(TextEditingController());
      _prenomControllers.add(TextEditingController());
      _placesSelectionnees.add(0);
    }
  }

  @override
  void dispose() {
    for (var controller in _nomControllers) {
      controller.dispose();
    }
    for (var controller in _prenomControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isPlaceDisponible(int place) {
    return !_placesOccupees.contains(place) && 
           !_placesSelectionnees.contains(place);
  }

  @override
  Widget build(BuildContext context) {
    final isPrestige = widget.classe == 'prestige';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.classe.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEFD807),
              ),
            ),
            Text(
              '${widget.depart} → ${widget.arrivee}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Passager en cours
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFD807).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEFD807)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFD807),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_passagerEnCours + 1}/${widget.nombrePassagers}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _prenomControllers[_passagerEnCours].text.isNotEmpty
                              ? '${_prenomControllers[_passagerEnCours].text} ${_nomControllers[_passagerEnCours].text}'
                              : 'Passager ${_passagerEnCours + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0F056B),
                          ),
                        ),
                        if (_placesSelectionnees[_passagerEnCours] != 0)
                          Text(
                            'Siège N°${_placesSelectionnees[_passagerEnCours]}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_placesSelectionnees[_passagerEnCours] != 0)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Formulaire
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenomControllers[_passagerEnCours],
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _nomControllers[_passagerEnCours],
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Légende
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendeItem('Disponible', Colors.green),
                  _buildLegendeItem('Occupée', Colors.grey),
                  _buildLegendeItem('Sélectionnée', const Color(0xFF0F056B)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Plan des sièges
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: _buildBusGrid(),
            ),
            const SizedBox(height: 12),
            // Récapitulatif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Passagers',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '${_placesSelectionnees.where((p) => p != 0).length}/${widget.nombrePassagers}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
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
                        '${(widget.prix * widget.nombrePassagers).toStringAsFixed(0)} FCFA',
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
                            '+${widget.points * widget.nombrePassagers} pts',
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _placesSelectionnees.every((p) => p != 0)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecapitulatifScreen(
                              depart: widget.depart,
                              arrivee: widget.arrivee,
                              date: widget.date,
                              heure: widget.heure,
                              prix: widget.prix,
                              nombrePassagers: widget.nombrePassagers,
                              points: widget.points,
                              classe: widget.classe,
                              passagers: List.generate(widget.nombrePassagers, (index) => {
                                'nom': _nomControllers[index].text,
                                'prenom': _prenomControllers[index].text,
                                'place': _placesSelectionnees[index],
                              }),
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFD807),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _placesSelectionnees.every((p) => p != 0)
                      ? 'CONFIRMER LA RÉSERVATION'
                      : 'Sélectionnez une place pour le passager ${_passagerEnCours + 1}',
                  style: const TextStyle(
                    fontSize: 14,
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

  Widget _buildBusGrid() {
    // Configuration du bus : 2 rangées gauche, allée, 2 rangées droite
    // Places de 11 à 37
    final List<List<int>> rows = [
      [11, 12, 13, 14],
      [15, 16, 17, 18],
      [19, 20, 21, 22],
      [23, 24, 25, 26],
      [27, 28, 29, 30],
      [31, 32, 33, 34],
      [35, 36, 37],
    ];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'VOLANT',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        ...rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Colonne 1 (gauche)
                if (row.length >= 2) _buildPlaceButton(row[0]),
                if (row.length >= 2) const SizedBox(width: 4),
                if (row.length >= 2) _buildPlaceButton(row[1]),
                // Allée
                const SizedBox(width: 16),
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                // Colonne 3 (droite)
                if (row.length >= 3) _buildPlaceButton(row[2]),
                if (row.length >= 4) const SizedBox(width: 4),
                if (row.length >= 4) _buildPlaceButton(row[3]),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orange, width: 1),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.door_front_door, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Text(
                'ENTRÉE DU BUS',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceButton(int place) {
    final isOccupied = _placesOccupees.contains(place);
    final isSelected = _placesSelectionnees.contains(place);
    final isCurrentSelected = _placesSelectionnees[_passagerEnCours] == place;

    return GestureDetector(
      onTap: () {
        if (!isOccupied && !isSelected && _passagerEnCours < widget.nombrePassagers) {
          setState(() {
            _placesSelectionnees[_passagerEnCours] = place;
            if (_nomControllers[_passagerEnCours].text.trim().isNotEmpty &&
                _prenomControllers[_passagerEnCours].text.trim().isNotEmpty) {
              if (_passagerEnCours < widget.nombrePassagers - 1) {
                _passagerEnCours++;
              }
            }
          });
        }
      },
      child: Container(
        width: 50,
        height: 40,
        decoration: BoxDecoration(
          color: isOccupied
              ? Colors.grey[300]
              : isCurrentSelected
                  ? const Color(0xFF0F056B)
                  : isSelected
                      ? Colors.green
                      : Colors.green[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOccupied
                ? Colors.grey[300]!
                : isCurrentSelected
                    ? const Color(0xFF0F056B)
                    : isSelected
                        ? Colors.green
                        : Colors.green[300]!,
            width: isCurrentSelected ? 3 : 2,
          ),
        ),
        child: Center(
          child: Text(
            place.toString(),
            style: TextStyle(
              color: isOccupied
                  ? Colors.grey[600]
                  : isCurrentSelected
                      ? Colors.white
                      : isSelected
                          ? Colors.white
                          : Colors.black87,
              fontWeight: isCurrentSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendeItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
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
}