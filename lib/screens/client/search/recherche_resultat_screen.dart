import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/catalog/catalog_departure.dart';
import 'package:catrans_app/models/catalog/catalog_search_criteria.dart';
import 'package:catrans_app/models/catalog/selected_departure_context.dart';
import 'package:catrans_app/screens/client/booking/choix_place_economie_screen.dart';
import 'package:catrans_app/screens/client/booking/choix_place_prestige_screen.dart';
import 'package:catrans_app/services/api/catalog_api_service.dart';

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
  final CatalogApiService _catalogApiService = CatalogApiService();

  List<CatalogDeparture> _departures = [];
  List<CatalogDeparture> _filteredDepartures = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTri = 'Heure';

  @override
  void initState() {
    super.initState();
    _loadDepartures();
  }

  Future<void> _loadDepartures() async {
    final criteria = widget.searchCriteria;

    if (criteria == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Recherche incomplète. Veuillez relancer la recherche.';
        _departures = [];
        _filteredDepartures = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _catalogApiService.getDepartures(
        stationId: criteria.stationId,
        destinationCityId: criteria.destinationCityId,
        date: criteria.date,
      );

      if (!mounted) return;

      final filtered = response.results
          .where((departure) => departure.serviceClass.uiCode == widget.classe)
          .toList();

      setState(() {
        _departures = response.results;
        _filteredDepartures = filtered;
        _isLoading = false;
      });
      _applySort();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _departures = [];
        _filteredDepartures = [];
        _isLoading = false;
        _errorMessage = _readableErrorMessage(error);
      });
    }
  }

  void _applySort() {
    final results = List<CatalogDeparture>.from(_filteredDepartures);

    if (_selectedTri == 'Prix') {
      results.sort((a, b) => _amount(a).compareTo(_amount(b)));
    } else if (_selectedTri == 'Prix décroissant') {
      results.sort((a, b) => _amount(b).compareTo(_amount(a)));
    } else {
      results.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    }

    setState(() => _filteredDepartures = results);
  }

  double _amount(CatalogDeparture departure) {
    return departure.fare.amountAsDouble ?? 0;
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

  String _readableErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  String _classLabel() {
    return widget.classe == 'prestige' ? 'Prestige' : 'Économie';
  }

  String _priceLabel(CatalogDeparture departure) {
    if (departure.fare.displayAmount.isNotEmpty) {
      return departure.fare.displayAmount;
    }

    return '${departure.fare.amount} ${departure.fare.currency}';
  }

  String _routeLabel(CatalogDeparture departure) {
    return departure.route.label ?? '${widget.depart} → ${widget.arrivee}';
  }

  bool _canReserve(CatalogDeparture departure) {
    return departure.bookingPolicy.salesOpen &&
        departure.seats.available >= widget.nombrePassagers;
  }

  String _unavailableMessage(CatalogDeparture departure) {
    if (!departure.bookingPolicy.salesOpen) {
      return departure.bookingPolicy.message.isNotEmpty
          ? departure.bookingPolicy.message
          : 'Vente fermée pour ce départ.';
    }

    if (departure.seats.available == 0) {
      return 'Complet';
    }

    if (departure.seats.available < widget.nombrePassagers) {
      return 'Places insuffisantes';
    }

    return '';
  }

  SelectedDepartureContext? _selectedContext(CatalogDeparture departure) {
    final criteria = widget.searchCriteria;
    if (criteria == null) return null;

    return SelectedDepartureContext(
      searchCriteria: criteria,
      departure: departure,
      selectedClass: widget.classe,
      passengerCount: widget.nombrePassagers,
      loyaltyPointsPerPassenger: widget.points,
    );
  }

  void _reserve(CatalogDeparture departure) {
    final selectedContext = _selectedContext(departure);
    final price = departure.fare.amountAsDouble ?? widget.prixUnitaire;

    if (widget.classe == 'economie') {
      context.push(
        RoutePaths.choixPlaceEconomie,
        extra: ChoixPlaceEconomieScreen(
          depart: widget.depart,
          arrivee: widget.arrivee,
          date: departure.departureDate,
          heure: departure.departureTime,
          prix: price,
          nombrePassagers: widget.nombrePassagers,
          points: widget.points,
          selectedDepartureContext: selectedContext,
        ),
      );
    } else {
      context.push(
        RoutePaths.choixPlacePrestige,
        extra: ChoixPlacePrestigeScreen(
          depart: widget.depart,
          arrivee: widget.arrivee,
          date: departure.departureDate,
          heure: departure.departureTime,
          prix: price,
          nombrePassagers: widget.nombrePassagers,
          points: widget.points,
          selectedDepartureContext: selectedContext,
        ),
      );
    }
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
                Flexible(
                  child: Text(
                    '${widget.depart} → ${widget.arrivee}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(widget.date),
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
            onPressed: _loadDepartures,
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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Départs réels - ${_formatDate(widget.date)}',
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_filteredDepartures.length} départs',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F056B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
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
                    onPressed: _showSortBottomSheet,
                    icon: const Icon(Icons.sort, color: Colors.white),
                    label: const Text(
                      'Trier',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0F056B)),
            SizedBox(height: 20),
            Text(
              'Recherche des départs...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDepartures,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFD807),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredDepartures.isEmpty) {
      final classLabel = _classLabel();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_bus, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'Aucun départ disponible en $classLabel pour cette date.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _departures.isEmpty
                    ? 'Aucun départ réel n’a été trouvé pour ce trajet.'
                    : 'Essayez une autre classe ou une autre date.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDepartures.length,
      itemBuilder: (context, index) {
        return _buildDepartureCard(_filteredDepartures[index]);
      },
    );
  }

  Widget _buildDepartureCard(CatalogDeparture departure) {
    final canReserve = _canReserve(departure);
    final unavailableMessage = _unavailableMessage(departure);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CA TRANS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F056B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _routeLabel(departure),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: canReserve ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    canReserve ? departure.status.label : unavailableMessage,
                    style: TextStyle(
                      color:
                          canReserve ? Colors.green[800] : Colors.orange[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
                  'Départ à ${departure.departureTime}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    departure.serviceClass.name,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prix',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _priceLabel(departure),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F056B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${departure.seats.available} place${departure.seats.available > 1 ? 's' : ''} disponible${departure.seats.available > 1 ? 's' : ''}',
                      style: TextStyle(
                        color:
                            departure.seats.available >= widget.nombrePassagers
                                ? Colors.green[800]
                                : Colors.orange[900],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: canReserve ? () => _reserve(departure) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFD807),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(120, 40),
                  ),
                  child: Text(
                    canReserve ? 'RÉSERVER' : 'INDISPONIBLE',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            if (!canReserve && unavailableMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                unavailableMessage,
                style: TextStyle(
                  color: Colors.orange[900],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    final options = ['Heure', 'Prix', 'Prix décroissant'];

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
                    setState(() => _selectedTri = option);
                    _applySort();
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
