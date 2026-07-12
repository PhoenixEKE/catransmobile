import 'package:flutter/material.dart';

class GestionSiegesScreen extends StatefulWidget {
  const GestionSiegesScreen({super.key});

  @override
  _GestionSiegesScreenState createState() => _GestionSiegesScreenState();
}

class _GestionSiegesScreenState extends State<GestionSiegesScreen> {
  int _nombrePlaces = 37;
  
  // Configuration des places Prestige
  int _prestigeDebut = 1;
  int _prestigeFin = 5;
  bool _prestigeConfigActive = false;
  
  List<int> _siegesBloques = [12, 18, 22, 29, 31];
  final TextEditingController _bloquerController = TextEditingController();
  final TextEditingController _prestigeDebutController = TextEditingController();
  final TextEditingController _prestigeFinController = TextEditingController();

  // Liste des places Prestige (calculée dynamiquement)
  List<int> get _placesPrestige {
    if (_prestigeDebut <= _prestigeFin && _prestigeFin <= _nombrePlaces) {
      return List.generate(_prestigeFin - _prestigeDebut + 1, (i) => _prestigeDebut + i);
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _prestigeDebutController.text = '1';
    _prestigeFinController.text = '5';
  }

  // Configurer les places Prestige
  void _configurerPrestige() {
    _prestigeDebutController.text = _prestigeDebut.toString();
    _prestigeFinController.text = _prestigeFin.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurer les places Prestige'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          width: 400,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Définissez la plage de numéros pour les places Prestige',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Plage de numéros
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prestigeDebutController,
                          decoration: const InputDecoration(
                            labelText: 'Début',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.start),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final val = int.tryParse(value);
                            if (val != null) {
                              setStateDialog(() {
                                _prestigeDebut = val.clamp(1, _nombrePlaces);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('à', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _prestigeFinController,
                          decoration: const InputDecoration(
                            labelText: 'Fin',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.arrow_forward),  // ← CORRIGÉ
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final val = int.tryParse(value);
                            if (val != null) {
                              setStateDialog(() {
                                _prestigeFin = val.clamp(1, _nombrePlaces);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Visualisation des places Prestige
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFD807).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEFD807)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Places Prestige',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFD807).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_placesPrestige.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFFEFD807),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _placesPrestige.map((num) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFD807),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'VIP $num',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_placesPrestige.isEmpty)
                          const Text(
                            'Aucune place Prestige configurée',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Statistiques
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Total places',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                '$_nombrePlaces',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFD807).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Places Prestige',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                '${_placesPrestige.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEFD807),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Places Standard',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                '${_nombrePlaces - _placesPrestige.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final debut = int.tryParse(_prestigeDebutController.text);
              final fin = int.tryParse(_prestigeFinController.text);
              
              if (debut != null && fin != null && debut <= fin && fin <= _nombrePlaces) {
                setState(() {
                  _prestigeDebut = debut;
                  _prestigeFin = fin;
                  _prestigeConfigActive = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Places Prestige configurées : ${_placesPrestige.length} places'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuration invalide. Vérifiez les numéros.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F056B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  // Bloquer un siège
  void _bloquerSiege() {
    final value = int.tryParse(_bloquerController.text);
    if (value != null && value > 0 && value <= _nombrePlaces) {
      if (_placesPrestige.contains(value)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Ce siège est une place Prestige'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      setState(() {
        if (!_siegesBloques.contains(value)) {
          _siegesBloques.add(value);
          _bloquerController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔒 Siège N°$value bloqué'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Siège déjà bloqué'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de siège invalide'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Débloquer un siège
  void _debloquerSiege(int siege) {
    setState(() {
      _siegesBloques.remove(siege);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔓 Siège N°$siege débloqué'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestion des Sièges'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F056B),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF0F056B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Configuration sauvegardée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Nombre de places
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_seat,
                      color: Color(0xFF0F056B),
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nombre de places',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (_nombrePlaces > 20) {
                                    setState(() {
                                      _nombrePlaces--;
                                      if (_prestigeFin > _nombrePlaces) {
                                        _prestigeFin = _nombrePlaces;
                                      }
                                    });
                                  }
                                },
                              ),
                              Text(
                                '$_nombrePlaces',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F056B),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  if (_nombrePlaces < 50) {
                                    setState(() {
                                      _nombrePlaces++;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Configuration des places Prestige
            Card(
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
                        const Text(
                          'Places Prestige',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _configurerPrestige,
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Configurer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F056B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Affichage des places Prestige
                    if (_placesPrestige.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFD807).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEFD807)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Places Prestige',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFD807).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_placesPrestige.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFFEFD807),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _placesPrestige.map((num) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFD807),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'VIP $num',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Text(
                            'Aucune place Prestige configurée',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Blocage de sièges
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blocage de sièges',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Sièges bloqués
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _siegesBloques.map((siege) {
                        return Chip(
                          label: Text('N°$siege'),
                          backgroundColor: Colors.red[100],
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                          onDeleted: () => _debloquerSiege(siege),
                        );
                      }).toList(),
                    ),
                    
                    if (_siegesBloques.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Aucun siège bloqué',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Formulaire de blocage
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bloquerController,
                            decoration: const InputDecoration(
                              hintText: 'Numéro de siège à bloquer',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _bloquerSiege,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('BLOQUER'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Résumé
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F056B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Total places', '$_nombrePlaces'),
                    _buildSummaryRow('Places Prestige', '${_placesPrestige.length}'),
                    _buildSummaryRow('Places Standard', '${_nombrePlaces - _placesPrestige.length}'),
                    _buildSummaryRow('Sièges bloqués', '${_siegesBloques.length}'),
                    _buildSummaryRow('Places disponibles', '${_nombrePlaces - _placesPrestige.length - _siegesBloques.length}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _configurerPrestige,
        backgroundColor: const Color(0xFFEFD807),
        foregroundColor: Colors.black,
        tooltip: 'Configurer les places Prestige',
        child: const Icon(Icons.stars),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}