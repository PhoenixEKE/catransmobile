import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/catalog/selected_departure_context.dart';
import 'package:catrans_app/screens/client/booking/recapitulatif_screen.dart';
import 'package:catrans_app/models/reservation/reservation_create_item.dart';
import 'package:catrans_app/services/api/reservation_api_service.dart';
import 'package:catrans_app/services/auth_service.dart';

class ChoixPlaceEconomieScreen extends StatefulWidget {
  final String depart;
  final String arrivee;
  final DateTime date;
  final String heure;
  final double prix;
  final int nombrePassagers;
  final int points;
  final SelectedDepartureContext? selectedDepartureContext;

  const ChoixPlaceEconomieScreen({
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
  _ChoixPlaceEconomieScreenState createState() =>
      _ChoixPlaceEconomieScreenState();
}

class _ChoixPlaceEconomieScreenState extends State<ChoixPlaceEconomieScreen> {
  final List<TextEditingController> _nomControllers = [];
  final List<TextEditingController> _prenomControllers = [];
  final List<TextEditingController> _phoneControllers = [];
  final ReservationApiService _reservationApiService = ReservationApiService();
  bool _isCreatingReservation = false;

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthService>().currentUser;
    for (int i = 0; i < widget.nombrePassagers; i++) {
      _nomControllers.add(TextEditingController(
        text: i == 0 ? currentUser?.lastname ?? '' : '',
      ));
      _prenomControllers.add(TextEditingController(
        text: i == 0 ? currentUser?.firstname ?? '' : '',
      ));
      _phoneControllers.add(TextEditingController(
        text: i == 0 ? currentUser?.phoneNumber ?? '' : '',
      ));
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
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _arePassengerFieldsFilled() {
    final hasCurrentUser = context.read<AuthService>().currentUser != null;

    for (int i = 0; i < widget.nombrePassagers; i++) {
      final isCurrentCustomer = i == 0 && hasCurrentUser;
      if (_nomControllers[i].text.trim().isEmpty ||
          _prenomControllers[i].text.trim().isEmpty) {
        return false;
      }

      if (!isCurrentCustomer && _phoneControllers[i].text.trim().isEmpty) {
        return false;
      }
    }

    return true;
  }

  List<Map<String, dynamic>> _buildPassengers() {
    return List.generate(widget.nombrePassagers, (index) {
      return {
        'nom': _nomControllers[index].text.trim(),
        'prenom': _prenomControllers[index].text.trim(),
        'telephone': _phoneControllers[index].text.trim(),
        'place': 0,
      };
    });
  }

  List<ReservationCreateItem> _buildReservationItems() {
    final hasCurrentUser = context.read<AuthService>().currentUser != null;

    return List.generate(widget.nombrePassagers, (index) {
      final isCurrentCustomer = index == 0 && hasCurrentUser;
      if (isCurrentCustomer) {
        return const ReservationCreateItem(
          isForCustomer: true,
          useLoyaltyPoints: false,
        );
      }

      return ReservationCreateItem(
        isForCustomer: false,
        useLoyaltyPoints: false,
        travelerLastname: _nomControllers[index].text.trim(),
        travelerFirstname: _prenomControllers[index].text.trim(),
        travelerPhone: _phoneControllers[index].text.trim(),
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RecapitulatifScreen.fromReservation(
            reservationDetail: reservation,
            isBlockingPendingResume: true,
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _confirmReservation() async {
    if (!_arePassengerFieldsFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final departureContext = widget.selectedDepartureContext;
    if (departureContext == null) {
      _showError(
          'Départ sélectionné introuvable. Veuillez relancer la recherche.');
      return;
    }

    setState(() {
      _isCreatingReservation = true;
    });

    try {
      final reservation =
          await _reservationApiService.createEconomyPendingReservation(
        departureId: departureContext.departureId,
        serviceClassCode: 'ECONOMIE',
        items: _buildReservationItems(),
      );

      if (!mounted) return;

      setState(() {
        _isCreatingReservation = false;
      });

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
            classe: 'economie',
            passagers: _buildPassengers(),
            reservationDetail: reservation,
          ),
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

      _showError(
        error is ApiException
            ? error.message
            : 'Impossible de créer la réservation en attente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.prix * widget.nombrePassagers;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'ÉCONOMIE',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'En classe Économie, les places vous seront attribuées à la gare par nos agents selon les places disponibles dans le car.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Informations des passagers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F056B),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(widget.nombrePassagers, (index) {
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
                      Text(
                        'Passager ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prenomControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Prénom',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _nomControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Nom',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneControllers[index],
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
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
                        '${widget.nombrePassagers}',
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
                          const Icon(Icons.stars,
                              color: Color(0xFFEFD807), size: 16),
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isCreatingReservation ? null : _confirmReservation,
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
                    : const Text(
                        'CONFIRMER LA RÉSERVATION',
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
