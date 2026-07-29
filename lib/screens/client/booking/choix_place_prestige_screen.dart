import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/booking/prestige_seat_layout.dart';
import 'package:catrans_app/models/booking/seat_hold_response.dart';
import 'package:catrans_app/models/booking/seat_map_response.dart';
import 'package:catrans_app/models/booking/seat_map_seat.dart';
import 'package:catrans_app/models/catalog/selected_departure_context.dart';
import 'package:catrans_app/models/loyalty/loyalty_account.dart';
import 'package:catrans_app/models/reservation/reservation_create_item.dart';
import 'package:catrans_app/screens/client/booking/recapitulatif_screen.dart';
import 'package:catrans_app/services/api/booking_api_service.dart';
import 'package:catrans_app/services/api/loyalty_api_service.dart';
import 'package:catrans_app/services/api/reservation_api_service.dart';
import 'package:catrans_app/services/auth_service.dart';

class ChoixPlacePrestigeScreen extends StatefulWidget {
  final String depart;
  final String arrivee;
  final DateTime date;
  final String heure;
  final double prix;
  final int nombrePassagers;
  final int points;
  final SelectedDepartureContext? selectedDepartureContext;

  const ChoixPlacePrestigeScreen({
    super.key,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.heure,
    required this.prix,
    required this.nombrePassagers,
    required this.points,
    this.selectedDepartureContext,
  });

  @override
  _ChoixPlacePrestigeScreenState createState() =>
      _ChoixPlacePrestigeScreenState();
}

class _ChoixPlacePrestigeScreenState extends State<ChoixPlacePrestigeScreen> {
  final List<TextEditingController> _nomControllers = [];
  final List<TextEditingController> _prenomControllers = [];
  final List<TextEditingController> _phoneControllers = [];
  final List<SeatMapSeat> _selectedSeats = [];
  final BookingApiService _bookingApiService = BookingApiService();
  final ReservationApiService _reservationApiService = ReservationApiService();
  final LoyaltyApiService _loyaltyApiService = LoyaltyApiService();

  SeatMapResponse? _seatMap;
  String? _seatMapError;
  int _passagerEnCours = 0;
  bool _isLoadingSeatMap = true;
  bool _isCreatingReservation = false;

  LoyaltyAccount? _loyaltyAccount;
  bool _useLoyaltyPoints = false;

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthService>().currentUser;
    for (int i = 0; i < widget.nombrePassagers; i++) {
      _prenomControllers.add(TextEditingController(
        text: i == 0 ? currentUser?.firstname ?? '' : '',
      ));
      _nomControllers.add(TextEditingController(
        text: i == 0 ? currentUser?.lastname ?? '' : '',
      ));
      _phoneControllers.add(TextEditingController(
        text: i == 0 ? currentUser?.phoneNumber ?? '' : '',
      ));
    }
    _loadSeatMap();
    _loadLoyaltyAccount();
  }

  /// Best-effort: the redemption toggle simply stays disabled if this fails
  /// or is still loading, it never blocks seat selection or confirmation.
  Future<void> _loadLoyaltyAccount() async {
    try {
      final account = await _loyaltyApiService.getAccount();
      if (!mounted) return;
      setState(() => _loyaltyAccount = account);
    } catch (_) {
      // Silently unavailable: toggle stays disabled, nothing else changes.
    }
  }

  bool get _canRedeemLoyaltyPoints =>
      _loyaltyAccount?.redemption.prestige.canRedeem ?? false;

  @override
  void dispose() {
    for (final controller in _nomControllers) {
      controller.dispose();
    }
    for (final controller in _prenomControllers) {
      controller.dispose();
    }
    for (final controller in _phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<int> get _selectedSeatNumbers =>
      _selectedSeats.map((seat) => seat.seatNumber).toList();

  bool get _isSelectionComplete =>
      _selectedSeats.length == widget.nombrePassagers;

  Future<void> _loadSeatMap() async {
    final departureContext = widget.selectedDepartureContext;
    if (departureContext == null) {
      setState(() {
        _isLoadingSeatMap = false;
        _seatMapError =
            'Départ sélectionné introuvable. Veuillez relancer la recherche.';
      });
      return;
    }

    setState(() {
      _isLoadingSeatMap = true;
      _seatMapError = null;
    });

    try {
      final rawSeatMap = await _bookingApiService.getSeatMap(
        departureId: departureContext.departureId,
      );
      // Le client ne doit voir que les sièges de la plage Prestige, pas
      // l'ensemble du bus avec les sièges hors plage grisés.
      final seatMap = SeatMapResponse(
        departure: rawSeatMap.departure,
        seatSelection: rawSeatMap.seatSelection,
        layout: rawSeatMap.layout,
        counts: rawSeatMap.counts,
        seats: rawSeatMap.seats
            .where((seat) => seat.isInServiceClassZone)
            .toList(),
      );

      if (!mounted) return;

      setState(() {
        _seatMap = seatMap;
        _selectedSeats.removeWhere(
          (selected) => !seatMap.seats.any(
            (seat) =>
                seat.seatNumber == selected.seatNumber &&
                seat.isAvailableForSelection,
          ),
        );
        _isLoadingSeatMap = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingSeatMap = false;
        _seatMapError = error is ApiException
            ? error.message
            : 'Impossible de charger le plan des sièges.';
      });
    }
  }

  List<Map<String, dynamic>> _buildPassengers({
    required List<int> seatNumbers,
  }) {
    return List.generate(widget.nombrePassagers, (index) {
      return {
        'nom': _nomControllers[index].text.trim(),
        'prenom': _prenomControllers[index].text.trim(),
        'telephone': _phoneControllers[index].text.trim(),
        'place': index < seatNumbers.length ? seatNumbers[index] : 0,
      };
    });
  }

  List<ReservationCreateItem> _buildReservationItems({
    required List<SeatHoldResponse> holds,
  }) {
    final currentUser = context.read<AuthService>().currentUser;
    final holdBySeatNumber = {
      for (final hold in holds) hold.seatNumber: hold,
    };
    final orderedHolds = _selectedSeatNumbers
        .map((seatNumber) => holdBySeatNumber[seatNumber])
        .whereType<SeatHoldResponse>()
        .toList();

    return List.generate(widget.nombrePassagers, (index) {
      final hold = index < orderedHolds.length ? orderedHolds[index] : holds[index];
      final isCurrentCustomer = index == 0 && currentUser != null;

      if (isCurrentCustomer) {
        return ReservationCreateItem(
          seatHoldId: hold.id,
          isForCustomer: true,
          useLoyaltyPoints: _useLoyaltyPoints && _canRedeemLoyaltyPoints,
        );
      }

      return ReservationCreateItem(
        seatHoldId: hold.id,
        isForCustomer: false,
        useLoyaltyPoints: false,
        travelerLastname: _nomControllers[index].text.trim(),
        travelerFirstname: _prenomControllers[index].text.trim(),
        travelerPhone: _phoneControllers[index].text.trim(),
      );
    });
  }

  void _showMessage(String message, {Color backgroundColor = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<bool> _openCurrentPendingReservation() async {
    try {
      final pending =
          await _reservationApiService.getCurrentPendingReservation();
      final reservation = pending.reservation;
      if (!mounted || reservation == null || !pending.hasActiveReservation) {
        return false;
      }

      context.go(
        RoutePaths.recapitulatif,
        extra: RecapitulatifScreen.fromReservation(
          reservationDetail: reservation,
          isBlockingPendingResume: true,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _redirectIfPendingAlreadyExists() async {
    final opened = await _openCurrentPendingReservation();
    return opened;
  }

  Future<void> _confirmPrestigeReservation() async {
    final departureContext = widget.selectedDepartureContext;
    if (departureContext == null) {
      _showMessage(
        'Départ sélectionné introuvable. Veuillez relancer la recherche.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_selectedSeats.length != widget.nombrePassagers) {
      _showMessage('Veuillez sélectionner ${widget.nombrePassagers} siège(s).');
      return;
    }

    setState(() {
      _isCreatingReservation = true;
    });

    try {
      final hasActivePending = await _redirectIfPendingAlreadyExists();
      if (hasActivePending) return;

      final holds = await _bookingApiService.createManualSeatHold(
        departureId: departureContext.departureId,
        seatNumbers: _selectedSeatNumbers,
      );

      final reservation = await _reservationApiService
          .createPrestigePendingReservation(
        items: _buildReservationItems(holds: holds),
      );

      if (!mounted) return;

      setState(() {
        _isCreatingReservation = false;
      });

      context.push(
        RoutePaths.recapitulatif,
        extra: RecapitulatifScreen(
          depart: widget.depart,
          arrivee: widget.arrivee,
          date: widget.date,
          heure: widget.heure,
          prix: widget.prix,
          nombrePassagers: widget.nombrePassagers,
          points: widget.points,
          classe: 'prestige',
          passagers: _buildPassengers(
            seatNumbers: reservation.items
                .map((item) => item.seatNumber)
                .whereType<int>()
                .toList(),
          ),
          reservationDetail: reservation,
          isBlockingPendingResume: true,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCreatingReservation = false;
      });

      if (error is ApiException && error.statusCode == 409) {
        final openedPending = await _openCurrentPendingReservation();
        if (openedPending) return;
      }

      _showMessage(
        error is ApiException
            ? error.message
            : 'Impossible de créer la réservation en attente.',
        backgroundColor: Colors.red,
      );

      await _loadSeatMap();
    }
  }

  void _toggleSeat(SeatMapSeat seat) {
    final existingIndex = _selectedSeats.indexWhere(
      (selected) => selected.seatNumber == seat.seatNumber,
    );

    if (existingIndex >= 0) {
      setState(() {
        _selectedSeats.removeAt(existingIndex);
        _passagerEnCours = _selectedSeats.length.clamp(
          0,
          widget.nombrePassagers - 1,
        ).toInt();
      });
      return;
    }

    if (!seat.isInServiceClassZone) {
      _showMessage('Ce siège n\'est pas disponible pour la classe Prestige.');
      return;
    }

    if (!seat.canSelect) {
      final isOccupied = seat.isHeld || seat.isReserved;
      _showMessage(
        isOccupied ? 'Ce siège n\'est plus disponible.' : 'Ce siège est indisponible.',
      );
      return;
    }

    if (_selectedSeats.length >= widget.nombrePassagers) {
      _showMessage('Vous avez déjà sélectionné le nombre de sièges nécessaire.');
      return;
    }

    setState(() {
      _selectedSeats.add(seat);
      _passagerEnCours = _selectedSeats.length.clamp(
        0,
        widget.nombrePassagers - 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.prix * widget.nombrePassagers;
    final passagerActuel = _passagerEnCours;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'PRESTIGE',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
            _buildCurrentPassengerCard(passagerActuel),
            const SizedBox(height: 12),
            _buildPassengerForm(passagerActuel),
            const SizedBox(height: 12),
            _buildLegend(),
            const SizedBox(height: 12),
            _buildSeatMapCard(),
            const SizedBox(height: 12),
            _buildSummary(total),
            const SizedBox(height: 16),
            _buildLoyaltyToggle(),
            const SizedBox(height: 16),
            _buildConfirmButton(passagerActuel),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPassengerCard(int passagerActuel) {
    final selectedSeat = passagerActuel < _selectedSeats.length
        ? _selectedSeats[passagerActuel].seatNumber
        : 0;

    return Container(
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
              '${passagerActuel + 1}/${widget.nombrePassagers}',
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
                  _prenomControllers[passagerActuel].text.isNotEmpty
                      ? '${_prenomControllers[passagerActuel].text} ${_nomControllers[passagerActuel].text}'
                      : 'Passager ${passagerActuel + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F056B),
                  ),
                ),
                if (selectedSeat != 0)
                  Text(
                    'Siège $selectedSeat',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (selectedSeat != 0)
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildPassengerForm(int passagerActuel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prenomControllers[passagerActuel],
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _nomControllers[passagerActuel],
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneControllers[passagerActuel],
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendeItem('Disponible', Colors.green),
          _buildLegendeItem('Sélectionné', const Color(0xFF0F056B)),
          _buildLegendeItem('Occupé', Colors.grey),
          _buildLegendeItem('Bloqué', Colors.red),
          _buildLegendeItem('Hors zone Prestige', Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _buildSeatMapCard() {
    return Container(
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
      child: _buildSeatMapContent(),
    );
  }

  Widget _buildSeatMapContent() {
    if (_isLoadingSeatMap) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF0F056B)),
            SizedBox(height: 12),
            Text('Chargement du plan des sièges...'),
          ],
        ),
      );
    }

    if (_seatMapError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 34),
            const SizedBox(height: 8),
            Text(
              _seatMapError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadSeatMap,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final seatMap = _seatMap;
    if (seatMap == null || seatMap.seats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Aucun siège disponible pour ce départ.'),
      );
    }

    return _buildBusGrid(seatMap);
  }

  Widget _buildBusGrid(SeatMapResponse seatMap) {
    final seatsByNumber = <int, SeatMapSeat>{
      for (final seat in seatMap.seats) seat.seatNumber: seat,
    };
    final rows = PrestigeSeatLayout.rowsFor(seatsByNumber.keys);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 116,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
                    Icon(Icons.add, color: Colors.grey, size: 15),
                  ],
                ),
                SizedBox(width: 6),
                Text(
                  'VOLANT',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        ...rows.map((row) => _buildBusSeatRow(row, seatsByNumber)),
      ],
    );
  }

  Widget _buildBusSeatRow(
    List<int?> row,
    Map<int, SeatMapSeat> seatsByNumber,
  ) {
    Widget slot(int? seatNumber) => Expanded(
          child: Center(
            child: seatNumber == null
                ? const SizedBox(width: 50, height: 40)
                : _buildSeatButton(seatsByNumber[seatNumber]!),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          slot(row[0]),
          slot(row[1]),
          const SizedBox(width: 32),
          slot(row[2]),
          slot(row[3]),
        ],
      ),
    );
  }

  Widget _buildSeatButton(SeatMapSeat seat) {
    final isSelected = _selectedSeatNumbers.contains(seat.seatNumber);
    final isOccupied = seat.isHeld || seat.isReserved;
    final isOutOfZone = seat.isOutOfServiceClassZone;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      backgroundColor = const Color(0xFF0F056B);
      borderColor = const Color(0xFF0F056B);
      textColor = Colors.white;
    } else if (isOutOfZone) {
      backgroundColor = Colors.grey.shade200;
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey.shade500;
    } else if (seat.isBlocked) {
      backgroundColor = Colors.red.shade100;
      borderColor = Colors.red.shade300;
      textColor = Colors.red.shade700;
    } else if (isOccupied || !seat.canSelect) {
      backgroundColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade400;
      textColor = Colors.grey.shade700;
    } else {
      backgroundColor = Colors.green.shade100;
      borderColor = Colors.green.shade300;
      textColor = Colors.black87;
    }

    return GestureDetector(
      onTap: _isCreatingReservation ? null : () => _toggleSeat(seat),
      child: Opacity(
        opacity: isOutOfZone ? 0.75 : 1,
        child: Container(
          width: 50,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 3 : 2,
            ),
          ),
          child: Center(
            child: Text(
              seat.displayLabel.isNotEmpty
                  ? seat.displayLabel
                  : seat.seatNumber.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(double total) {
    return Container(
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
                '${_selectedSeats.length}/${widget.nombrePassagers}',
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
                '${total.toStringAsFixed(0)} FCFA',
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
    );
  }

  /// Renders nothing while the loyalty account hasn't loaded yet (best
  /// effort, see `_loadLoyaltyAccount`) rather than a disabled control with
  /// no context. Eligibility and the missing-points figures both come from
  /// the account's real `redemption` status, not a local guess - Prestige's
  /// rule is composite (total points AND a minimum earned via Prestige
  /// tickets specifically), so only the clause(s) actually unmet are shown.
  Widget _buildLoyaltyToggle() {
    final account = _loyaltyAccount;
    if (account == null) return const SizedBox.shrink();

    final eligibility = account.redemption.prestige;
    final canRedeem = eligibility.canRedeem;
    final missingParts = <String>[
      if (eligibility.missingTotalPoints > 0)
        '${eligibility.missingTotalPoints} pts au total',
      if ((eligibility.missingPrestigePoints ?? 0) > 0)
        '${eligibility.missingPrestigePoints} pts issus de Prestige',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFEFD807)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Utiliser mes points de fidélité',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: _useLoyaltyPoints && canRedeem,
                onChanged: canRedeem
                    ? (value) => setState(() => _useLoyaltyPoints = value)
                    : null,
                activeThumbColor: const Color(0xFF0F056B),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            canRedeem
                ? 'Solde : ${account.pointsBalance} pts. Rend ce billet gratuit (${eligibility.rule}).'
                : 'Solde : ${account.pointsBalance} pts. Il vous manque ${missingParts.join(' et ')} (${eligibility.rule}).',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (_useLoyaltyPoints && canRedeem) ...[
            const SizedBox(height: 6),
            const Text(
              'Vos points seront débités dès la confirmation de la réservation.',
              style: TextStyle(fontSize: 12, color: Color(0xFFB54708)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmButton(int passagerActuel) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isCreatingReservation ? null : _confirmPrestigeReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEFD807),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreatingReservation
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Création de la réservation en attente...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              )
            : Text(
                _isSelectionComplete
                    ? 'CONFIRMER LA RÉSERVATION'
                    : 'Sélectionnez ${widget.nombrePassagers} siège(s)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }

  Widget _buildLegendeItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
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
