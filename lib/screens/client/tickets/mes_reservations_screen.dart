import 'package:flutter/material.dart';

import 'package:catrans_app/models/trip/client_trip.dart';
import 'package:catrans_app/screens/client/tickets/billet_screen.dart';
import 'package:catrans_app/services/api/trip_api_service.dart';

class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});

  @override
  _MesReservationsScreenState createState() => _MesReservationsScreenState();
}

class _MesReservationsScreenState extends State<MesReservationsScreen> {
  final TripApiService _tripApiService = TripApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ClientTrip> _upcomingTrips = const [];
  List<ClientTrip> _historyTrips = const [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        _tripApiService.getUpcomingTrips(),
        _tripApiService.getHistoryTrips(),
      ]);

      if (!mounted) return;

      setState(() {
        _upcomingTrips = responses[0].results;
        _historyTrips = responses[1].results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  String _getMonth(DateTime date) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[date.month - 1];
  }

  Color _getStatutColor(String statusCode) {
    switch (statusCode) {
      case 'issued':
        return Colors.green;
      case 'used':
        return Colors.blue;
      case 'cancelled':
      case 'expired':
      case 'invalidated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(ClientTrip trip) {
    switch (trip.status.code) {
      case 'issued':
        return 'Confirmée';
      case 'used':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      case 'expired':
        return 'Expirée';
      case 'invalidated':
        return 'Invalidée';
      default:
        return trip.statusLabel.isNotEmpty
            ? trip.statusLabel
            : 'Statut inconnu';
    }
  }

  bool _isPrestige(ClientTrip trip) {
    final value = trip.serviceClassLabel.toLowerCase();
    return value.contains('prestige');
  }

  String _classLabel(ClientTrip trip) {
    final label = trip.serviceClassLabel.trim();
    return label.isEmpty ? 'Classe' : label.toUpperCase();
  }

  DateTime _tripDate(ClientTrip trip) {
    return trip.departureDate ?? DateTime.now();
  }

  String _tripDeparture(ClientTrip trip) {
    return trip.trip.departureStation ?? 'Départ';
  }

  String _tripDestination(ClientTrip trip) {
    return trip.trip.destination ?? 'Arrivée';
  }

  double _tripAmount(ClientTrip trip) {
    final amount = trip.payment.amount;
    if (amount == null) return 0;
    return double.tryParse(amount) ?? 0;
  }

  Map<String, dynamic> _passengerFromTrip(ClientTrip trip) {
    final fullName = trip.traveler.fullName?.trim();
    final parts = fullName == null || fullName.isEmpty
        ? <String>[]
        : fullName.split(RegExp(r'\s+'));

    return {
      'prenom': parts.isEmpty ? 'Voyageur' : parts.first,
      'nom': parts.length <= 1 ? '' : parts.sublist(1).join(' '),
      'place': trip.trip.seatNumber ?? 0,
      'seat_display': trip.seatDisplayLabel,
      'ticket_id': trip.ticket.id,
    };
  }

  void _openTripTicket(ClientTrip trip) {
    final passagers = [_passengerFromTrip(trip)];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BilletScreen(
          depart: _tripDeparture(trip),
          arrivee: _tripDestination(trip),
          date: _tripDate(trip),
          heure: trip.trip.departureTime ?? '--:--',
          classe: trip.serviceClassLabel,
          prix: _tripAmount(trip),
          nombrePassagers: passagers.length,
          passagers: passagers,
          reference: trip.ticket.reference,
          ticketId: trip.ticket.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Mes Réservations'),
          backgroundColor: const Color(0xFF0F056B),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'À VENIR'),
              Tab(text: 'PASSÉES'),
            ],
            indicatorColor: Color(0xFFEFD807),
            labelColor: Color(0xFFEFD807),
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildTripList(_upcomingTrips, 'à venir'),
            _buildTripList(_historyTrips, 'passées'),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(List<ClientTrip> trips, String type) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F056B)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (trips.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: const Color(0xFF0F056B),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return _buildTripCard(trips[index]);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 20),
            Text(
              'Impossible de charger vos voyages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Veuillez réessayer.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadTrips,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFD807),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'RÉESSAYER',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'à venir' ? Icons.airplane_ticket_outlined : Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            type == 'à venir'
                ? 'Aucune réservation à venir'
                : 'Aucune réservation passée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            type == 'à venir'
                ? 'Réservez votre prochain trajet'
                : 'Vos réservations apparaîtront ici',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 30),
          if (type == 'à venir')
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFD807),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'RECHERCHER UN TRAJET',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard(ClientTrip trip) {
    final date = _tripDate(trip);
    final statusLabel = _statusLabel(trip);
    final statusColor = _getStatutColor(trip.status.code);
    final isPrestige = _isPrestige(trip);

    return GestureDetector(
      onTap: () => _openTripTicket(trip),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F056B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.day.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F056B),
                      ),
                    ),
                    Text(
                      _getMonth(date),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F056B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _tripDeparture(trip),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward,
                            size: 16, color: Colors.grey),
                        Flexible(
                          child: Text(
                            _tripDestination(trip),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              trip.trip.departureTime ?? '--:--',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPrestige
                                ? const Color(0xFFEFD807).withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _classLabel(trip),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPrestige
                                  ? const Color(0xFFEFD807)
                                  : Colors.blue,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_seat,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              trip.seatDisplayLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (trip.payment.displayAmount != null)
                          Text(
                            trip.payment.displayAmount!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F056B),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.traveler.fullName ?? trip.ticket.reference,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
