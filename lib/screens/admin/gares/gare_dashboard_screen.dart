import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GareDashboardScreen extends StatefulWidget {
  const GareDashboardScreen({super.key});

  @override
  _GareDashboardScreenState createState() => _GareDashboardScreenState();
}

class _GareDashboardScreenState extends State<GareDashboardScreen> {
  int _selectedTab = 0;
  final TextEditingController _codeController = TextEditingController();
  final List<Map<String, dynamic>> _validations = [];
  bool _isScanning = false;
  String _scannedData = '';

  final List<Map<String, dynamic>> _departs = [
    {'heure': '08:00', 'trajet': 'Dakar → Saint-Louis', 'bus': 'BUS-001', 'statut': 'En cours', 'embarques': 22},
    {'heure': '10:30', 'trajet': 'Dakar → Thiès', 'bus': 'BUS-002', 'statut': 'Programmé', 'embarques': 0},
    {'heure': '12:00', 'trajet': 'Thiès → Mbour', 'bus': 'BUS-003', 'statut': 'Programmé', 'embarques': 0},
    {'heure': '14:00', 'trajet': 'Dakar → Kaolack', 'bus': 'BUS-004', 'statut': 'Programmé', 'embarques': 0},
  ];

  void _simulerScan() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scannedData = '';
    });

    Future.delayed(const Duration(seconds: 2), () {
      final randomId = DateTime.now().millisecondsSinceEpoch.toString().substring(6, 12);
      final reference = 'CIT-2024-${randomId}';
      _scannedData = reference;
      
      final dejaValide = _validations.any((v) => v['reference'] == reference);
      
      if (dejaValide) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Ce billet a déjà été validé !'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final newValidation = {
        'reference': reference,
        'statut': 'Validé',
        'date': DateTime.now(),
        'passager': 'Amadou Diop',
        'trajet': 'Dakar → Saint-Louis',
        'place': 7,
      };

      setState(() {
        _isScanning = false;
        _validations.insert(0, newValidation);
      });

      _showBilletDetails(context, reference);
    });
  }

  void _showBilletDetails(BuildContext context, String reference) {
    final validation = _validations.firstWhere(
      (v) => v['reference'] == reference,
      orElse: () => {},
    );

    if (validation.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            const Text('Billet Validé'),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Référence', validation['reference']),
                    const Divider(),
                    _buildDetailRow('Passager', validation['passager']),
                    _buildDetailRow('Trajet', validation['trajet']),
                    _buildDetailRow('Place', 'N°${validation['place']}'),
                    _buildDetailRow('Date', DateTime.now().toString().substring(0, 16)),
                    _buildDetailRow('Statut', '✅ Validé'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: QrImageView(
                    data: validation['reference'],
                    size: 100,
                    backgroundColor: Colors.white,
                    version: QrVersions.auto,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Code QR du billet validé',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🖨️ Impression du ticket en cours...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Imprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F056B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _saisirCode() {
    _codeController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir le code du billet'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez la référence du billet à valider',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: 'Ex: CIT-2024-12345',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _codeController.text.trim();
              if (code.isNotEmpty) {
                final dejaValide = _validations.any((v) => v['reference'] == code);
                
                if (dejaValide) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Ce billet a déjà été validé !'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() {
                  _validations.insert(0, {
                    'reference': code,
                    'statut': 'Validé',
                    'date': DateTime.now(),
                    'passager': 'Client',
                    'trajet': 'Trajet inconnu',
                    'place': 'N/A',
                  });
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Billet validé avec succès !'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un code'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F056B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildStatItem('Départs', '8', Icons.departure_board, Colors.blue)),
                Expanded(child: _buildStatItem('Arrivées', '6', Icons.flight_land, Colors.green)),
                Expanded(child: _buildStatItem('Voyageurs', '142', Icons.people, Colors.orange)),
                Expanded(child: _buildStatItem('Validés', '${_validations.length}', Icons.check_circle, Colors.purple)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab('Validation', 0),
                const SizedBox(width: 8),
                _buildTab('Embarquement', 1),
                const SizedBox(width: 8),
                _buildTab('Départs', 2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildValidationTab()
                : _selectedTab == 1
                    ? _buildEmbarquementTab()
                    : _buildDepartsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _selectedTab == index ? const Color(0xFF0F056B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selectedTab == index ? const Color(0xFF0F056B) : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedTab == index ? Colors.white : Colors.black87,
              fontWeight: _selectedTab == index ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ TAB VALIDATION - CORRIGÉ (overflow)
  Widget _buildValidationTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Scanner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _buildCardDecoration(),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isScanning 
                        ? Colors.green[100] 
                        : const Color(0xFF0F056B).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isScanning ? Colors.green : const Color(0xFF0F056B),
                      width: _isScanning ? 3 : 2,
                    ),
                  ),
                  child: Icon(
                    _isScanning ? Icons.qr_code_scanner : Icons.qr_code,
                    size: 40,
                    color: _isScanning ? Colors.green : const Color(0xFF0F056B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isScanning ? 'Scan en cours...' : 'Scanner un QR Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isScanning ? Colors.green : const Color(0xFF0F056B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isScanning 
                      ? 'Veuillez placer le QR code devant la caméra' 
                      : 'Validez les billets en scannant le QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isScanning ? Colors.green[700] : Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _simulerScan,
                        icon: Icon(
                          _isScanning ? Icons.stop : Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          _isScanning ? 'ARRÊTER' : 'SCANNER',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isScanning 
                              ? Colors.red 
                              : const Color(0xFF0F056B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isScanning ? null : _saisirCode,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('SAISIR CODE', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isScanning) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Scannez le QR code du billet du client',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // ✅ Liste des validations - CORRIGÉ
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Derniers billets validés',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_validations.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // ✅ Liste avec Expanded
                  Expanded(
                    child: _validations.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Aucune validation',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Scannez un billet pour commencer',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _validations.length > 8 ? 8 : _validations.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final validation = _validations[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.green[100],
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                                ),
                                title: Text(
                                  validation['reference'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                subtitle: Text(
                                  validation['passager'],
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Validé',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      validation['date'].toString().substring(0, 16),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _showBilletDetails(
                                    context,
                                    validation['reference'],
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbarquementTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
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
                        'Bus #BUS-001',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'En attente',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dakar → Saint-Louis • 08:00',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Embarqués',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                '22/37',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'En attente',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                '15',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Embarquement confirmé !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('CONFIRMER L\'EMBARQUEMENT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartsTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _buildCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Départs du jour',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._departs.map((depart) => _buildDepartItem(depart)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartItem(Map<String, dynamic> depart) {
    final color = depart['statut'] == 'En cours' ? Colors.orange : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                depart['heure'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                depart['trajet'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${depart['bus']} • ${depart['embarques']}/37',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              depart['statut'],
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}