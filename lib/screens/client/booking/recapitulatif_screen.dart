import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/booking/selected_seat_hold_context.dart';
import 'package:catrans_app/models/payment/wave_current_payment_response.dart';
import 'package:catrans_app/models/reservation/reservation_detail.dart';
import 'package:catrans_app/services/api/payment_api_service.dart';
import 'package:catrans_app/services/api/reservation_api_service.dart';
import 'package:catrans_app/screens/client/booking/paiement_screen.dart';

class RecapitulatifScreen extends StatelessWidget {
  final String depart;
  final String arrivee;
  final DateTime date;
  final String heure;
  final double prix;
  final int nombrePassagers;
  final int points;
  final String classe;
  final List<Map<String, dynamic>> passagers;
  final SelectedSeatHoldContext? selectedSeatHoldContext;
  final ReservationDetail? reservationDetail;
  final bool isBlockingPendingResume;

  const RecapitulatifScreen({
    super.key,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.heure,
    required this.prix,
    required this.nombrePassagers,
    required this.points,
    required this.classe,
    required this.passagers,
    this.selectedSeatHoldContext,
    this.reservationDetail,
    this.isBlockingPendingResume = false,
  });

  factory RecapitulatifScreen.fromReservation({
    Key? key,
    required ReservationDetail reservationDetail,
    bool isBlockingPendingResume = false,
  }) {
    final items = reservationDetail.items;
    final firstItem = items.isNotEmpty ? items.first : null;
    final travelDate = DateTime.tryParse(firstItem?.departureDate ?? '') ??
        reservationDetail.createdAt ??
        DateTime.now();
    final unitPrice = double.tryParse(
          firstItem?.unitPrice ?? reservationDetail.totalAmount,
        ) ??
        0;
    final serviceClassCode = firstItem?.serviceClassCode?.toLowerCase() ?? '';
    final passengers = items.isEmpty
        ? <Map<String, dynamic>>[
            {
              'nom': '',
              'prenom': 'Voyageur',
              'telephone': '',
              'place': 0,
            }
          ]
        : items.map((item) {
            return <String, dynamic>{
              'nom': item.travelerLastname ?? '',
              'prenom': item.travelerFirstname ?? 'Voyageur',
              'telephone': item.travelerPhone ?? '',
              'place': item.seatNumber ?? 0,
            };
          }).toList();

    return RecapitulatifScreen(
      key: key,
      depart: firstItem?.stationName ?? 'Départ',
      arrivee: firstItem?.destinationName ?? 'Arrivée',
      date: travelDate,
      heure: firstItem?.departureTime ?? '',
      prix: unitPrice,
      nombrePassagers: passengers.length,
      points: 0,
      classe: serviceClassCode == 'prestige' ? 'prestige' : 'economie',
      passagers: passengers,
      reservationDetail: reservationDetail,
      isBlockingPendingResume: isBlockingPendingResume,
    );
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

  String _formatDateTime(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$day/$month/${localDate.year} à $hour:$minute';
  }

  String _referenceLabel() {
    return reservationDetail != null
        ? 'Référence de réservation'
        : 'Référence temporaire';
  }

  String _referenceValue() {
    final reservation = reservationDetail;
    if (reservation != null && reservation.reference.isNotEmpty) {
      return reservation.reference;
    }

    final holds = selectedSeatHoldContext?.holds ?? const [];
    if (holds.isNotEmpty && holds.first.id.isNotEmpty) {
      final compactId = holds.first.id.replaceAll('-', '').toUpperCase();
      final suffix = compactId.length > 6
          ? compactId.substring(compactId.length - 6)
          : compactId;
      return 'HOLD-$suffix';
    }

    return 'TEMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6, 12)}';
  }

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(reservationDetail?.totalAmount ?? '') ??
        prix * nombrePassagers;
    final isPrestige = classe == 'prestige';

    final scaffold = Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Récapitulatif'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Réservation en attente',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Finalisez votre paiement pour reserver votre siege.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          color: Color(0xFF0F056B),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _referenceLabel(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _referenceValue(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F056B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reservationDetail != null) ...[
                    _buildReservationInfoCard(reservationDetail!),
                    const SizedBox(height: 20),
                  ] else if (selectedSeatHoldContext != null) ...[
                    _buildHoldInfoCard(selectedSeatHoldContext!),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Informations du trajet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.route, 'Trajet', '$depart → $arrivee'),
                  _buildInfoRow(
                      Icons.calendar_today, 'Date', _formatDate(date)),
                  _buildInfoRow(Icons.access_time, 'Heure de départ', heure),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPrestige
                          ? const Color(0xFFEFD807).withOpacity(0.2)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isPrestige ? const Color(0xFFEFD807) : Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPrestige
                              ? Icons.stars
                              : Icons.airline_seat_recline_normal,
                          color: isPrestige
                              ? const Color(0xFFEFD807)
                              : Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Classe ${classe.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isPrestige
                                      ? const Color(0xFFEFD807)
                                      : Colors.blue,
                                ),
                              ),
                              Text(
                                isPrestige
                                    ? 'Collation • Toilettes • Sans escale'
                                    : 'Confort • Prix accessible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPrestige
                                ? const Color(0xFFEFD807)
                                : Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${prix.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Passagers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...passagers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final passager = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isPrestige
                                  ? const Color(0xFFEFD807).withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPrestige
                                      ? const Color(0xFFEFD807)
                                      : Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${passager['prenom']} ${passager['nom']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                if (passager['place'] != 0)
                                  Text(
                                    'Siège ${passager['place']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (passager['place'] != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Siège ${passager['place']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F056B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0F056B).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nombre de passagers',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$nombrePassagers',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total à payer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${total.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F056B),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Color(0xFFEFD807),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Points gagnés',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFD807).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFEFD807),
                                ),
                              ),
                              child: Text(
                                '+${points * nombrePassagers} pts',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEFD807),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(context, total),
          ],
        ),
      ),
    );

    final paymentAwareScaffold = reservationDetail == null
        ? scaffold
        : _RecapitulatifPaymentRecoveryGate(
            reservationDetail: reservationDetail!,
            paymentScreenBuilder: (currentPayment) => PaiementScreen(
              reservationDetail: reservationDetail,
              depart: depart,
              arrivee: arrivee,
              date: date,
              heure: heure,
              prix: prix,
              nombrePassagers: nombrePassagers,
              points: points,
              classe: classe,
              passagers: passagers,
              total: total,
              existingPayment: currentPayment.payment,
              canStartNewPayment: currentPayment.canStartNewPayment,
            ),
            child: scaffold,
          );

    if (!isBlockingPendingResume) {
      return paymentAwareScaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showBlockingReturnMessage(context);
      },
      child: paymentAwareScaffold,
    );
  }

  void _showBlockingReturnMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vous devez payer ou annuler cette réservation avant de continuer.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, double total) {
    final canCancel = reservationDetail?.isPendingPayment == true;
    var isCancelling = false;

    return StatefulBuilder(
      builder: (context, setButtonState) {
        Future<void> cancelPendingReservation() async {
          final reservation = reservationDetail;
          if (reservation == null || isCancelling) return;

          setButtonState(() {
            isCancelling = true;
          });

          try {
            await ReservationApiService().cancelReservation(
              reservationId: reservation.id,
            );

            if (!context.mounted) return;

            final messenger = ScaffoldMessenger.of(context);
            context.go(RoutePaths.accueil);

            messenger.showSnackBar(
              const SnackBar(
                content: Text('Réservation annulée.'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (error) {
            if (!context.mounted) return;

            setButtonState(() {
              isCancelling = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error is ApiException
                      ? error.message
                      : 'Impossible d’annuler la réservation.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isCancelling
                    ? null
                    : () {
                        context.push(
                          RoutePaths.paiement,
                          extra: PaiementScreen(
                            reservationDetail: reservationDetail,
                            depart: depart,
                            arrivee: arrivee,
                            date: date,
                            heure: heure,
                            prix: prix,
                            nombrePassagers: nombrePassagers,
                            points: points,
                            classe: classe,
                            passagers: passagers,
                            total: total,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFD807),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'PAYER AVEC WAVE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            if (canCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: isCancelling ? null : cancelPendingReservation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isCancelling
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Annulation en cours...'),
                          ],
                        )
                      : const Text(
                          'ANNULER LA RÉSERVATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReservationInfoCard(ReservationDetail reservation) {
    final expiresAt = reservation.localExpiresAt;
    final withoutSeat = reservation.isEconomyWithoutSeat ||
        !reservation.items.any((item) => item.hasSeat);
    final seatLabels = reservation.items
        .where((item) => item.hasSeat)
        .map((item) => item.seatDisplayLabel)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_turned_in, color: Colors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Réservation en attente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                if (withoutSeat)
                  Text(
                    'Placement effectué à la gare',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  )
                else if (seatLabels.isNotEmpty)
                  Text(
                    seatLabels.join(', '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                if (expiresAt != null)
                  Text(
                    'À payer avant le ${_formatDateTime(expiresAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldInfoCard(SelectedSeatHoldContext context) {
    final expiresAt = context.firstExpiresAt;
    final seatNumbers = context.seatNumbers;
    final placesLabel = context.holds.length == 1
        ? '1 place gardée'
        : '${context.holds.length} places gardées';
    final seatsLabel = seatNumbers.length == 1
        ? 'Siège attribué : ${seatNumbers.first}'
        : 'Sièges attribués : ${seatNumbers.join(', ')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_seat, color: Colors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Places gardées',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  placesLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                if (seatNumbers.isNotEmpty)
                  Text(
                    seatsLabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                if (expiresAt != null)
                  Text(
                    'À payer avant le ${_formatDateTime(expiresAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapitulatifPaymentRecoveryGate extends StatefulWidget {
  final ReservationDetail reservationDetail;
  final Widget child;
  final Widget Function(WaveCurrentPaymentResponse currentPayment)
      paymentScreenBuilder;

  const _RecapitulatifPaymentRecoveryGate({
    required this.reservationDetail,
    required this.child,
    required this.paymentScreenBuilder,
  });

  @override
  State<_RecapitulatifPaymentRecoveryGate> createState() =>
      _RecapitulatifPaymentRecoveryGateState();
}

class _RecapitulatifPaymentRecoveryGateState
    extends State<_RecapitulatifPaymentRecoveryGate> {
  final PaymentApiService _paymentApiService = PaymentApiService();

  bool _isCheckingPayment = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkCurrentPayment();
      }
    });
  }

  Future<void> _checkCurrentPayment() async {
    try {
      final currentPayment =
          await _paymentApiService.getCurrentWavePaymentForReservation(
        reservationId: widget.reservationDetail.id,
      );

      if (!mounted) return;

      if (currentPayment.shouldGoToPaymentScreen &&
          currentPayment.payment != null) {
        context.go(
          RoutePaths.paiement,
          extra: widget.paymentScreenBuilder(currentPayment),
        );
        return;
      }
    } catch (_) {
      // Fallback prudent : le récap reste accessible si la récupération échoue.
    }

    if (!mounted) return;
    setState(() {
      _isCheckingPayment = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCheckingPayment) return widget.child;

    return Stack(
      children: [
        widget.child,
        Container(
          color: Colors.black.withOpacity(0.08),
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Vérification du paiement...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
