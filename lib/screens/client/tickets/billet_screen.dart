import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/ticket/ticket_digital.dart';
import 'package:catrans_app/services/api/ticket_api_service.dart';

class BilletScreen extends StatefulWidget {
  final String depart;
  final String arrivee;
  final DateTime date;
  final String heure;
  final String classe;
  final double prix;
  final int nombrePassagers;
  final List<Map<String, dynamic>> passagers;
  final String reference;
  final String? ticketId;

  const BilletScreen({
    super.key,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.heure,
    required this.classe,
    required this.prix,
    required this.nombrePassagers,
    required this.passagers,
    required this.reference,
    this.ticketId,
  });

  @override
  State<BilletScreen> createState() => _BilletScreenState();
}

class _BilletScreenState extends State<BilletScreen> {
  final TicketApiService _ticketApiService = TicketApiService();

  TicketDigital? _ticketDigital;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _hasBackendTicketId => widget.ticketId?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    if (_hasBackendTicketId) {
      _loadTicketDigital();
    }
  }

  Future<void> _loadTicketDigital() async {
    final ticketId = widget.ticketId?.trim();
    if (ticketId == null || ticketId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ticket = await _ticketApiService.getTicketDigital(
        ticketId: ticketId,
      );
      if (!mounted) return;
      setState(() {
        _ticketDigital = ticket;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ApiException
            ? error.message
            : 'Impossible de charger le billet.';
        _isLoading = false;
      });
    }
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

  String _reference(TicketDigital? ticket) {
    return ticket?.reference.isNotEmpty == true
        ? ticket!.reference
        : widget.reference;
  }

  String? _reservationReference(TicketDigital? ticket) {
    final reference = ticket?.reservation?.reference.trim();
    return reference == null || reference.isEmpty ? null : reference;
  }

  String _depart(TicketDigital? ticket) {
    return ticket?.trip.departureStation?.trim().isNotEmpty == true
        ? ticket!.trip.departureStation!
        : widget.depart;
  }

  String _arrivee(TicketDigital? ticket) {
    return ticket?.trip.destination?.trim().isNotEmpty == true
        ? ticket!.trip.destination!
        : widget.arrivee;
  }

  DateTime _date(TicketDigital? ticket) {
    return ticket?.trip.parsedDepartureDate ?? widget.date;
  }

  String _heure(TicketDigital? ticket) {
    return ticket?.trip.departureTime?.trim().isNotEmpty == true
        ? ticket!.trip.departureTime!
        : widget.heure;
  }

  String _classe(TicketDigital? ticket) {
    return ticket?.trip.serviceClass?.trim().isNotEmpty == true
        ? ticket!.trip.serviceClass!
        : widget.classe;
  }

  String _statusLabel(TicketDigital? ticket) {
    return ticket?.status.label.trim().isNotEmpty == true
        ? ticket!.status.label
        : 'Valide';
  }

  String _priceDisplay(TicketDigital? ticket) {
    final displayAmount = ticket?.payment.displayAmount?.trim();
    if (displayAmount != null && displayAmount.isNotEmpty) {
      return displayAmount;
    }

    final amount = ticket?.payment.amount?.trim();
    if (amount != null && amount.isNotEmpty) {
      return '$amount ${ticket?.payment.currency ?? 'XOF'}';
    }

    return '${(widget.prix * widget.nombrePassagers).toStringAsFixed(0)} FCFA';
  }

  List<Map<String, dynamic>> _passagers(TicketDigital? ticket) {
    if (ticket == null) return widget.passagers;

    final fullName = ticket.traveler.fullName?.trim();
    final firstname = ticket.traveler.firstname?.trim();
    final lastname = ticket.traveler.lastname?.trim();

    return [
      {
        'prenom': firstname?.isNotEmpty == true
            ? firstname
            : fullName?.isNotEmpty == true
                ? fullName
                : 'Voyageur',
        'nom': lastname?.isNotEmpty == true ? lastname : '',
        'place': ticket.trip.seatNumber ?? 0,
        'seat_display': ticket.seatDisplayLabel,
      }
    ];
  }

  String _seatDisplayLabel(
    TicketDigital? ticket,
    Map<String, dynamic> passager,
  ) {
    if (ticket != null) return ticket.seatDisplayLabel;

    final seatDisplay = passager['seat_display']?.toString().trim();
    if (seatDisplay != null && seatDisplay.isNotEmpty) return seatDisplay;

    final place = passager['place'];
    if (place is int && place > 0) return 'Siège $place';
    if (place is String && place.trim().isNotEmpty && place != '0') {
      return 'Siège $place';
    }

    return 'Placement effectué à la gare';
  }

  String? _qrData(TicketDigital? ticket) {
    if (ticket != null && ticket.hasQrValue) return ticket.qr.value;
    return null;
  }

  String _qrInstruction(TicketDigital? ticket) {
    final instruction = ticket?.qr.instruction?.trim();
    if (instruction != null && instruction.isNotEmpty) return instruction;
    return 'Présentez ce QR code à l\'embarquement';
  }

  void _shareBillet(BuildContext context) {
    final ticket = _ticketDigital;
    final reference = _reference(ticket);
    final depart = _depart(ticket);
    final arrivee = _arrivee(ticket);
    final date = _date(ticket);
    final heure = _heure(ticket);
    final classe = _classe(ticket);
    final passagers = _passagers(ticket);
    final priceDisplay = _priceDisplay(ticket);

    final String message = '''
┌─────────────────────────────┐
│         🚌 CITRANS          │
│                              │
│   Référence: $reference     │
│   Trajet: $depart → $arrivee│
│   Date: ${_formatDate(date)}│
│   Heure: $heure              │
│   Classe: ${classe.toUpperCase()}│
│   Passagers: ${passagers.length}│
│   Prix: $priceDisplay│
│                              │
│   Présentez le billet       │
│   officiel à l'embarquement │
└─────────────────────────────┘
''';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final canShare = _ticketDigital?.actions.canShare ?? true;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mon ticket'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: canShare ? () => _shareBillet(context) : null,
            tooltip: 'Partager',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF0F056B)),
            SizedBox(height: 16),
            Text('Chargement du billet...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _hasBackendTicketId) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTicketDigital,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F056B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildTicketContent(_ticketDigital);
  }

  Widget _buildTicketContent(TicketDigital? ticket) {
    final reference = _reference(ticket);
    final reservationReference = _reservationReference(ticket);
    final depart = _depart(ticket);
    final arrivee = _arrivee(ticket);
    final date = _date(ticket);
    final heure = _heure(ticket);
    final classe = _classe(ticket);
    final passagers = _passagers(ticket);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Référence',
                        reference,
                        icon: Icons.confirmation_number,
                      ),
                      if (reservationReference != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Réservation',
                          reservationReference,
                          icon: Icons.bookmark,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Statut',
                        _statusLabel(ticket),
                        icon: Icons.verified,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Trajet',
                        '$depart → $arrivee',
                        icon: Icons.route,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              'Date',
                              _formatDate(date),
                              icon: Icons.calendar_today,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoRow(
                              'Heure',
                              heure,
                              icon: Icons.access_time,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Classe',
                        classe.toUpperCase(),
                        icon: Icons.stars,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Passagers',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F056B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...passagers.map(
                        (passager) => _buildPassengerRow(ticket, passager),
                      ),
                      const SizedBox(height: 20),
                      _buildQrBlock(ticket),
                      const SizedBox(height: 12),
                      _buildTravelConditionsNotice(),
                    ],
                  ),
                ),
                _buildTotalFooter(ticket),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                context.go(RoutePaths.accueil);
              },
              icon: const Icon(Icons.home, color: Color(0xFF0F056B)),
              label: const Text(
                'RETOUR À L\'ACCUEIL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F056B),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0F056B), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F056B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/icons/logo.png',
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.directions_bus,
                  size: 30,
                  color: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerRow(
    TicketDigital? ticket,
    Map<String, dynamic> passager,
  ) {
    final seatLabel = _seatDisplayLabel(ticket, passager);
    final hasSeat = seatLabel.startsWith('Siège');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0F056B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                hasSeat ? seatLabel.replaceFirst('Siège ', '') : 'Gare',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F056B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${passager['prenom'] ?? 'Voyageur'} ${passager['nom'] ?? ''}'
                  .trim(),
            ),
          ),
          Text(
            seatLabel,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQrBlock(TicketDigital? ticket) {
    final qrData = _qrData(ticket);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            if (qrData != null) ...[
              QrImageView(
                data: qrData,
                size: 150,
                backgroundColor: Colors.white,
                version: QrVersions.auto,
              ),
              const SizedBox(height: 10),
              Text(
                _qrInstruction(ticket),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.qr_code_2,
                size: 46,
                color: Color(0xFF0F056B),
              ),
              const SizedBox(height: 10),
              const Text(
                'QR temporairement indisponible. Actualisez le billet ou téléchargez le PDF officiel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTravelConditionsNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFD807).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF0F056B)),
          const SizedBox(width: 8),
          Expanded(
            child: const Text(
              '1. Enregistrement 30 min avant le départ\n'
              '2. Passé le délai, contactez le service client\n'
              '3. Ticket non remboursable',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF0F056B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFooter(TicketDigital? ticket) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F056B).withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Prix total',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            _priceDisplay(ticket),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F056B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
