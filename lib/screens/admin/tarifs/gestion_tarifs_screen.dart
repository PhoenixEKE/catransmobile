import 'package:flutter/material.dart';

class GestionTarifsScreen extends StatefulWidget {
  const GestionTarifsScreen({super.key});

  @override
  _GestionTarifsScreenState createState() => _GestionTarifsScreenState();
}

class _GestionTarifsScreenState extends State<GestionTarifsScreen> {
  bool _isLoading = true;
  
  final List<String> _lignesDisponibles = [
    'Dakar → Thiès',
    'Dakar → Saint-Louis',
    'Dakar → Mbour',
    'Dakar → Kaolack',
    'Dakar → Ziguinchor',
    'Thiès → Mbour',
    'Thiès → Dakar',
    'Saint-Louis → Dakar',
    'Saint-Louis → Louga',
  ];

  List<Map<String, dynamic>> _tarifs = [];

  @override
  void initState() {
    super.initState();
    _chargerTarifs();
  }

  void _chargerTarifs() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _tarifs = [
          {
            'id': '1',
            'ligne': 'Dakar → Thiès',
            'economie': 1500,
            'prestige': 2500,
            'promotion': false,
            'promotionPrix': 0,
          },
          {
            'id': '2',
            'ligne': 'Dakar → Saint-Louis',
            'economie': 3500,
            'prestige': 4500,
            'promotion': true,
            'promotionPrix': 2800,
          },
          {
            'id': '3',
            'ligne': 'Thiès → Mbour',
            'economie': 2000,
            'prestige': 3000,
            'promotion': false,
            'promotionPrix': 0,
          },
        ];
        _isLoading = false;
      });
    });
  }

  // ✅ AJOUTER UN TARIF - CORRIGÉ
  void _ajouterTarif() {
    // Contrôleurs locaux
    final TextEditingController prixEconomieController = TextEditingController();
    final TextEditingController prixPrestigeController = TextEditingController();
    final TextEditingController prixPromotionController = TextEditingController();
    String? selectedLigne;
    bool promotionActive = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Ajouter un tarif',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Liste déroulante des lignes
                    DropdownButtonFormField<String>(
                      value: selectedLigne,
                      decoration: const InputDecoration(
                        labelText: 'Ligne',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                      ),
                      hint: const Text('Sélectionnez une ligne'),
                      isExpanded: true,
                      items: _lignesDisponibles.map((ligne) {
                        final existe = _tarifs.any((t) => t['ligne'] == ligne);
                        return DropdownMenuItem<String>(
                          value: ligne,
                          enabled: !existe,
                          child: Row(
                            children: [
                              Expanded(child: Text(ligne)),
                              if (existe)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedLigne = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Prix Économie
                    TextField(
                      controller: prixEconomieController,
                      decoration: const InputDecoration(
                        labelText: 'Prix Économie (FCFA)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money, color: Color(0xFF0F056B)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Prix Prestige
                    TextField(
                      controller: prixPrestigeController,
                      decoration: const InputDecoration(
                        labelText: 'Prix Prestige (FCFA)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stars, color: Color(0xFFEFD807)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Promotion
                    Row(
                      children: [
                        Checkbox(
                          value: promotionActive,
                          onChanged: (value) {
                            setStateDialog(() {
                              promotionActive = value ?? false;
                              if (!promotionActive) {
                                prixPromotionController.clear();
                              }
                            });
                          },
                          activeColor: const Color(0xFFEFD807),
                        ),
                        const Text('Activer la promotion'),
                      ],
                    ),
                    
                    if (promotionActive) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: prixPromotionController,
                        decoration: const InputDecoration(
                          labelText: 'Prix Promotion (FCFA)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_offer, color: Colors.red),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
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
                    // ✅ Validation
                    if (selectedLigne == null || selectedLigne!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez sélectionner une ligne'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final economie = int.tryParse(prixEconomieController.text);
                    final prestige = int.tryParse(prixPrestigeController.text);

                    if (economie == null || prestige == null || economie <= 0 || prestige <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer des prix valides'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    if (promotionActive) {
                      final promotion = int.tryParse(prixPromotionController.text);
                      if (promotion == null || promotion <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez entrer un prix de promotion valide'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                    }

                    // ✅ Ajouter le tarif
                    setState(() {
                      _tarifs.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'ligne': selectedLigne,
                        'economie': economie,
                        'prestige': prestige,
                        'promotion': promotionActive,
                        'promotionPrix': promotionActive 
                            ? int.tryParse(prixPromotionController.text) ?? 0
                            : 0,
                      });
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Tarif ajouté avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F056B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ MODIFIER UN TARIF
  void _modifierTarif(Map<String, dynamic> tarif, int index) {
    final TextEditingController prixEconomieController = TextEditingController(
      text: tarif['economie'].toString(),
    );
    final TextEditingController prixPrestigeController = TextEditingController(
      text: tarif['prestige'].toString(),
    );
    final TextEditingController prixPromotionController = TextEditingController(
      text: tarif['promotionPrix']?.toString() ?? '',
    );
    bool promotionActive = tarif['promotion'] ?? false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Modifier le tarif',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne (non modifiable)
                    TextField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Ligne',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                      ),
                      controller: TextEditingController(text: tarif['ligne']),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Prix Économie
                    TextField(
                      controller: prixEconomieController,
                      decoration: const InputDecoration(
                        labelText: 'Prix Économie (FCFA)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money, color: Color(0xFF0F056B)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Prix Prestige
                    TextField(
                      controller: prixPrestigeController,
                      decoration: const InputDecoration(
                        labelText: 'Prix Prestige (FCFA)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stars, color: Color(0xFFEFD807)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Promotion
                    Row(
                      children: [
                        Checkbox(
                          value: promotionActive,
                          onChanged: (value) {
                            setStateDialog(() {
                              promotionActive = value ?? false;
                              if (!promotionActive) {
                                prixPromotionController.clear();
                              }
                            });
                          },
                          activeColor: const Color(0xFFEFD807),
                        ),
                        const Text('Activer la promotion'),
                      ],
                    ),
                    
                    if (promotionActive) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: prixPromotionController,
                        decoration: const InputDecoration(
                          labelText: 'Prix Promotion (FCFA)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_offer, color: Colors.red),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
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
                    final economie = int.tryParse(prixEconomieController.text);
                    final prestige = int.tryParse(prixPrestigeController.text);

                    if (economie == null || prestige == null || economie <= 0 || prestige <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer des prix valides'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    if (promotionActive) {
                      final promotion = int.tryParse(prixPromotionController.text);
                      if (promotion == null || promotion <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez entrer un prix de promotion valide'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                    }

                    setState(() {
                      _tarifs[index] = {
                        'id': tarif['id'],
                        'ligne': tarif['ligne'],
                        'economie': economie,
                        'prestige': prestige,
                        'promotion': promotionActive,
                        'promotionPrix': promotionActive 
                            ? int.tryParse(prixPromotionController.text) ?? 0
                            : 0,
                      };
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Tarif modifié avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F056B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Modifier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ SUPPRIMER UN TARIF
  void _supprimerTarif(int index) {
    final tarif = _tarifs[index];
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le tarif'),
          content: Text(
            'Voulez-vous vraiment supprimer le tarif pour la ligne "${tarif['ligne']}" ?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _tarifs.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Tarif supprimé'),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestion des Tarifs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F056B),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0F056B)),
            onPressed: _ajouterTarif,
            tooltip: 'Ajouter un tarif',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F056B)),
            onPressed: _chargerTarifs,
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
                  Text('Chargement des tarifs...'),
                ],
              ),
            )
          : _tarifs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Aucun tarif disponible',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Cliquez sur le bouton + pour ajouter un tarif',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tarifs.length,
                  itemBuilder: (context, index) {
                    final tarif = _tarifs[index];
                    final hasPromotion = tarif['promotion'] == true;

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
                                  tarif['ligne'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (hasPromotion)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Promotion',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _modifierTarif(tarif, index),
                                      tooltip: 'Modifier',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _supprimerTarif(index),
                                      tooltip: 'Supprimer',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Économie',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${tarif['economie']} FCFA',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFD807).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Prestige',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${tarif['prestige']} FCFA',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEFD807),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (hasPromotion) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.local_offer,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Prix promotion: ${tarif['promotionPrix']} FCFA',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterTarif,
        backgroundColor: const Color(0xFF0F056B),
        foregroundColor: Colors.white,
        tooltip: 'Ajouter un tarif',
        child: const Icon(Icons.add),
      ),
    );
  }
}