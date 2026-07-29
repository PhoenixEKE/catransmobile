import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/catalog/catalog_destination.dart';
import 'package:catrans_app/models/catalog/catalog_popular_route.dart';
import 'package:catrans_app/models/catalog/catalog_promotion.dart';
import 'package:catrans_app/models/catalog/catalog_search_criteria.dart';
import 'package:catrans_app/models/catalog/catalog_station.dart';
import 'package:catrans_app/models/catalog/catalog_travel_date.dart';
import 'package:catrans_app/widgets/client/bottom_nav_bar.dart';
import 'package:catrans_app/widgets/client/trajet_populaire.dart';
import 'package:catrans_app/widgets/client/hero_promo.dart';
import 'package:catrans_app/screens/client/search/choix_classe_screen.dart';
import 'package:catrans_app/services/api/catalog_api_service.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  _AccueilScreenState createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  int _selectedIndex = 0;
  final CatalogApiService _catalogApiService = CatalogApiService();

  List<CatalogStation> _stations = [];
  List<CatalogDestination> _destinations = [];
  List<CatalogTravelDate> _travelDates = [];
  List<CatalogPromotion> _promotions = [];
  List<CatalogPopularRoute> _popularRoutes = [];

  CatalogStation? _selectedStation;
  CatalogDestination? _selectedDestination;
  CatalogTravelDate? _selectedTravelDate;

  bool _isLoadingStations = false;
  bool _isLoadingDestinations = false;
  bool _isLoadingDates = false;
  bool _isLoadingPromotions = false;
  bool _isLoadingPopularRoutes = false;

  String? _stationsError;
  String? _destinationsError;
  String? _datesError;
  String? _promotionsError;
  String? _popularRoutesError;

  bool _showAllTrajets = false;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _loadPromotions();
    _loadPopularRoutes();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoadingStations = true;
      _stationsError = null;
    });

    try {
      final stations = await _catalogApiService.getStations();
      if (!mounted) return;

      setState(() {
        _stations = stations;
        _isLoadingStations = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _stations = [];
        _destinations = [];
        _travelDates = [];
        _selectedStation = null;
        _selectedDestination = null;
        _selectedTravelDate = null;
        _isLoadingStations = false;
        _stationsError = _readableErrorMessage(error);
      });
    }
  }

  Future<void> _loadDestinations(CatalogStation station) async {
    setState(() {
      _isLoadingDestinations = true;
      _destinationsError = null;
    });

    try {
      final destinations = await _catalogApiService.getDestinations(
        stationId: station.id,
      );
      if (!mounted) return;

      setState(() {
        _destinations = destinations;
        _isLoadingDestinations = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _destinations = [];
        _travelDates = [];
        _selectedDestination = null;
        _selectedTravelDate = null;
        _isLoadingDestinations = false;
        _destinationsError = _readableErrorMessage(error);
      });
    }
  }

  Future<void> _loadDates({
    required CatalogStation station,
    required CatalogDestination destination,
  }) async {
    setState(() {
      _isLoadingDates = true;
      _datesError = null;
    });

    try {
      final dates = await _catalogApiService.getDates(
        stationId: station.id,
        destinationCityId: destination.id,
      );
      if (!mounted) return;

      setState(() {
        _travelDates = dates;
        _isLoadingDates = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _travelDates = [];
        _selectedTravelDate = null;
        _isLoadingDates = false;
        _datesError = _readableErrorMessage(error);
      });
    }
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoadingPromotions = true;
      _promotionsError = null;
    });

    try {
      final promotions = await _catalogApiService.getPromotions();
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        _isLoadingPromotions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _promotions = [];
        _isLoadingPromotions = false;
        _promotionsError = _readableErrorMessage(error);
      });
    }
  }

  Future<void> _loadPopularRoutes() async {
    setState(() {
      _isLoadingPopularRoutes = true;
      _popularRoutesError = null;
    });

    try {
      final routes = await _catalogApiService.getPopularRoutes(limit: 10);
      if (!mounted) return;
      setState(() {
        _popularRoutes = routes;
        _isLoadingPopularRoutes = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _popularRoutes = [];
        _isLoadingPopularRoutes = false;
        _popularRoutesError = _readableErrorMessage(error);
      });
    }
  }

  void _onStationChanged(CatalogStation? station) {
    setState(() {
      _selectedStation = station;
      _selectedDestination = null;
      _selectedTravelDate = null;
      _destinations = [];
      _travelDates = [];
      _destinationsError = null;
      _datesError = null;
    });

    if (station != null) {
      _loadDestinations(station);
    }
  }

  void _onDestinationChanged(CatalogDestination? destination) {
    final station = _selectedStation;

    setState(() {
      _selectedDestination = destination;
      _selectedTravelDate = null;
      _travelDates = [];
      _datesError = null;
    });

    if (station != null && destination != null) {
      _loadDates(station: station, destination: destination);
    }
  }

  Future<void> _selectTravelDate() async {
    if (_selectedStation == null) {
      _showMessage('Veuillez sélectionner une gare de départ.');
      return;
    }

    if (_selectedDestination == null) {
      _showMessage('Veuillez sélectionner une destination.');
      return;
    }

    if (_isLoadingDates) {
      _showMessage('Chargement des dates disponibles...');
      return;
    }

    if (_travelDates.isEmpty) {
      _showMessage('Aucune date disponible pour ce trajet.');
      return;
    }

    final selectedDate = await showModalBottomSheet<CatalogTravelDate>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Dates disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F056B),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _travelDates.length,
                  itemBuilder: (context, index) {
                    final travelDate = _travelDates[index];
                    final isSelected = travelDate == _selectedTravelDate;

                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: const Color(0xFF0F056B),
                      ),
                      title: Text(_formatDate(travelDate.date)),
                      subtitle: Text(
                        '${travelDate.departuresCount} départ${travelDate.departuresCount > 1 ? 's' : ''} disponible${travelDate.departuresCount > 1 ? 's' : ''}',
                      ),
                      onTap: () => Navigator.pop(context, travelDate),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedDate == null) return;

    setState(() {
      _selectedTravelDate = selectedDate;
    });
  }

  void _search() {
    final station = _selectedStation;
    final destination = _selectedDestination;
    final travelDate = _selectedTravelDate;

    if (station == null) {
      _showMessage('Veuillez sélectionner une gare de départ.');
      return;
    }

    if (destination == null) {
      _showMessage('Veuillez sélectionner une destination.');
      return;
    }

    if (travelDate == null) {
      _showMessage('Veuillez sélectionner une date de départ.');
      return;
    }

    final criteria = CatalogSearchCriteria(
      station: station,
      destination: destination,
      travelDate: travelDate,
    );

    context.push(
      RoutePaths.choixClasse,
      extra: ChoixClasseScreen(
        depart: criteria.stationName,
        arrivee: criteria.destinationName,
        date: criteria.date,
        searchCriteria: criteria,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _readableErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  Widget _buildInlineStatus({
    required String message,
    bool isError = false,
    VoidCallback? onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 16,
            color: isError ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red : Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularRoutes() {
    if (_isLoadingPopularRoutes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_popularRoutesError != null) {
      return _buildInlineStatus(
        message: _popularRoutesError!,
        isError: true,
        onRetry: _loadPopularRoutes,
      );
    }

    if (_popularRoutes.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleRoutes =
        _showAllTrajets ? _popularRoutes : _popularRoutes.take(3).toList();

    return Column(
      children: visibleRoutes
          .map((route) => TrajetPopulaire(
                depart: route.departureStationName,
                arrivee: route.destinationName,
                prix: route.fareAmount,
                detail: '${route.popularityCount} réservations',
              ))
          .toList(),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Mes billets
      context.push(RoutePaths.mesReservations).then((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    } else if (index == 2) {
      // Support
      context.push(RoutePaths.support).then((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    } else if (index == 3) {
      // Profil
      context.push(RoutePaths.profil).then((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final prenom = user?.firstname ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prenom.isNotEmpty ? 'Bonjour $prenom 👋' : 'Bonjour 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F056B),
                        ),
                      ),
                      const Text(
                        'Où souhaitez-vous aller ?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 30,
                          color: Color(0xFF0F056B),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Aucune notification pour le moment'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Formulaire de recherche
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Départ
                    DropdownButtonFormField<CatalogStation>(
                      value: _selectedStation,
                      decoration: InputDecoration(
                        labelText: 'Départ',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Color(0xFF0F056B),
                        ),
                        suffixIcon: _isLoadingStations
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: _stations.map((station) {
                        return DropdownMenuItem<CatalogStation>(
                          value: station,
                          child: Text(
                            station.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _isLoadingStations ? null : _onStationChanged,
                    ),
                    if (_stationsError != null)
                      _buildInlineStatus(
                        message: _stationsError!,
                        isError: true,
                        onRetry: _loadStations,
                      )
                    else if (!_isLoadingStations && _stations.isEmpty)
                      _buildInlineStatus(
                        message: 'Aucune gare de départ disponible.',
                      ),

                    const SizedBox(height: 10),

                    // Bouton permuter désactivé : le catalogue backend est directionnel.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.swap_vert,
                            color: Colors.grey,
                            size: 30,
                          ),
                          onPressed: null,
                          tooltip: 'Permutation indisponible',
                        ),
                      ],
                    ),

                    // Arrivée
                    DropdownButtonFormField<CatalogDestination>(
                      value: _selectedDestination,
                      decoration: InputDecoration(
                        labelText: 'Arrivée',
                        prefixIcon: const Icon(
                          Icons.flag,
                          color: Color(0xFF0F056B),
                        ),
                        suffixIcon: _isLoadingDestinations
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: _destinations.map((destination) {
                        return DropdownMenuItem<CatalogDestination>(
                          value: destination,
                          child: Text(
                            destination.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged:
                          _selectedStation == null || _isLoadingDestinations
                              ? null
                              : _onDestinationChanged,
                    ),
                    if (_destinationsError != null)
                      _buildInlineStatus(
                        message: _destinationsError!,
                        isError: true,
                        onRetry: _selectedStation == null
                            ? null
                            : () => _loadDestinations(_selectedStation!),
                      )
                    else if (_selectedStation != null &&
                        !_isLoadingDestinations &&
                        _destinations.isEmpty)
                      _buildInlineStatus(
                        message:
                            'Aucune destination disponible depuis cette gare.',
                      ),

                    const SizedBox(height: 15),

                    // Date
                    InkWell(
                      onTap: _selectTravelDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date de départ',
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF0F056B),
                          ),
                          suffixIcon: _isLoadingDates
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : null,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        child: Text(
                          _selectedTravelDate == null
                              ? 'Sélectionnez une date disponible'
                              : _formatDate(_selectedTravelDate!.date),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_datesError != null)
                      _buildInlineStatus(
                        message: _datesError!,
                        isError: true,
                        onRetry: _selectedStation == null ||
                                _selectedDestination == null
                            ? null
                            : () => _loadDates(
                                  station: _selectedStation!,
                                  destination: _selectedDestination!,
                                ),
                      )
                    else if (_selectedDestination != null &&
                        !_isLoadingDates &&
                        _travelDates.isEmpty)
                      _buildInlineStatus(
                        message: 'Aucune date disponible pour ce trajet.',
                      ),

                    const SizedBox(height: 20),

                    // Bouton RECHERCHER
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFD807),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'RECHERCHER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Promotions
              const Text(
                'Promotions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F056B),
                ),
              ),
              const SizedBox(height: 15),

              HeroPromo(
                promotions: _promotions,
                isLoading: _isLoadingPromotions,
                error: _promotionsError,
              ),

              const SizedBox(height: 30),

              // Trajets populaires
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trajets populaires',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                  TextButton(
                    onPressed: _popularRoutes.length <= 3
                        ? null
                        : () {
                            setState(() {
                              _showAllTrajets = !_showAllTrajets;
                            });
                          },
                    child: Text(
                      _showAllTrajets ? 'VOIR MOINS' : 'VOIR TOUT',
                      style: TextStyle(
                        color: const Color(0xFF0F056B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildPopularRoutes(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
