import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/payment/wave_payment_response.dart';
import 'package:catrans_app/models/reservation/reservation_detail.dart';
import 'package:catrans_app/screens/client/home/accueil_screen.dart';
import 'package:catrans_app/services/api/payment_api_service.dart';

class PaiementScreen extends StatefulWidget {
  final ReservationDetail? reservationDetail;
  final String depart;
  final String arrivee;
  final DateTime date;
  final String heure;
  final double prix;
  final int nombrePassagers;
  final int points;
  final String classe;
  final List<Map<String, dynamic>> passagers;
  final double total;

  const PaiementScreen({
    super.key,
    this.reservationDetail,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.heure,
    required this.prix,
    required this.nombrePassagers,
    required this.points,
    required this.classe,
    required this.passagers,
    required this.total,
  });

  @override
  _PaiementScreenState createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  final PaymentApiService _paymentApiService = PaymentApiService();

  WavePaymentResponse? _payment;
  bool _isCreatingCheckout = false;
  bool _isCheckingStatus = false;
  bool _hasOpenedWave = false;
  String? _errorMessage;

  bool get _isBusy => _isCreatingCheckout || _isCheckingStatus;

  ReservationDetail? get _reservation => widget.reservationDetail;

  String get _reservationReference {
    final reference = _reservation?.reference;
    if (reference != null && reference.isNotEmpty) return reference;
    return 'Réservation en attente';
  }

  double get _total {
    final reservationTotal = double.tryParse(_reservation?.totalAmount ?? '');
    return reservationTotal ?? widget.total;
  }

  int get _passengerCount {
    final reservationItems = _reservation?.items.length ?? 0;
    return reservationItems > 0 ? reservationItems : widget.nombrePassagers;
  }

  String get _statusLabel {
    final payment = _payment;
    if (payment == null) return 'En attente de paiement';
    if (payment.isSuccess) return 'Paiement confirmé';
    if (payment.isPendingLike) return 'Paiement non confirmé';
    if (payment.isFailed) return 'Paiement échoué';
    if (payment.isCancelled) return 'Paiement annulé';
    if (payment.isExpired) return 'Délai de paiement expiré';
    if (payment.isAnomaly) return 'Paiement en anomalie';
    return 'Statut paiement : ${payment.status}';
  }

  Color get _statusColor {
    final payment = _payment;
    if (payment == null || payment.isPendingLike) return Colors.orange;
    if (payment.isSuccess) return Colors.green;
    if (payment.isAnomaly) return Colors.deepOrange;
    if (payment.isTerminal) return Colors.red;
    return const Color(0xFF0F056B);
  }

  String get _statusMessage {
    final payment = _payment;
    if (payment == null) {
      return 'Vous allez être redirigé vers Wave pour finaliser le paiement.';
    }
    if (payment.isSuccess) {
      return 'Paiement confirmé. Votre réservation est validée.';
    }
    if (payment.isPendingLike) {
      return 'Votre paiement n’a pas encore été validé par Wave. Si votre solde est insuffisant, rechargez votre compte Wave puis rouvrez le paiement.';
    }
    if (payment.isFailed) {
      return 'Le paiement a échoué. Vérifiez votre solde Wave puis réessayez.';
    }
    if (payment.isCancelled) return 'Le paiement a été annulé dans Wave.';
    if (payment.isExpired) {
      return 'Le délai de paiement a expiré. Veuillez relancer votre réservation.';
    }
    if (payment.isAnomaly) {
      return 'Paiement reçu mais non confirmé automatiquement. Contactez le support.';
    }
    return payment.message ?? 'Statut paiement mis à jour.';
  }

  Future<void> _startWavePayment() async {
    final reservation = _reservation;
    if (reservation == null || reservation.id.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Réservation introuvable. Veuillez relancer le parcours.';
      });
      return;
    }

    setState(() {
      _isCreatingCheckout = true;
      _errorMessage = null;
    });

    try {
      final payment = await _paymentApiService.createWaveCheckoutSession(
        reservationId: reservation.id,
      );

      if (!mounted) return;

      setState(() {
        _payment = payment;
        _isCreatingCheckout = false;
      });

      if (payment.canOpenWave) {
        await _openWaveUrl(payment.wave!.waveLaunchUrl!);
      } else if (mounted) {
        setState(() {
          _errorMessage = payment.message ??
              'Lien Wave indisponible. Veuillez vérifier le statut du paiement.';
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCreatingCheckout = false;
        _errorMessage = _messageFromError(error);
      });
    }
  }

  Future<void> _openWaveUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      setState(() {
        _errorMessage = 'Lien Wave invalide.';
      });
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;

    setState(() {
      _hasOpenedWave = opened;
      if (!opened) {
        _errorMessage = 'Impossible d’ouvrir Wave.';
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    final payment = _payment;
    if (payment == null || !payment.canCheckStatus) {
      setState(() {
        _errorMessage = 'Paiement Wave introuvable.';
      });
      return;
    }

    setState(() {
      _isCheckingStatus = true;
      _errorMessage = null;
    });

    try {
      final updatedPayment = await _paymentApiService.getWavePaymentStatus(
        paymentId: payment.paymentId,
      );

      if (!mounted) return;

      setState(() {
        _payment = updatedPayment;
        _isCheckingStatus = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCheckingStatus = false;
        _errorMessage = _messageFromError(error);
      });
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    return 'Impossible d’initialiser le paiement Wave pour le moment.';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$day/$month/${localDate.year} à $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final reservation = _reservation;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCard(reservation),
            const SizedBox(height: 16),
            _buildWaveCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(_errorMessage!),
            ],
            const SizedBox(height: 20),
            _buildActions(reservation),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ReservationDetail? reservation) {
    final expiresAt = reservation?.localExpiresAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé de la réservation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Référence', _reservationReference),
          _buildDetailRow('Trajet', '${widget.depart} → ${widget.arrivee}'),
          _buildDetailRow('Classe', widget.classe.toUpperCase()),
          _buildDetailRow('Passagers', '$_passengerCount'),
          _buildDetailRow(
            'Date & heure',
            '${_formatDate(widget.date)} à ${widget.heure}',
          ),
          if (expiresAt != null)
            _buildDetailRow('À payer avant', _formatDateTime(expiresAt)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F056B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.waves, color: Colors.blue, size: 30),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wave',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Paiement sécurisé via Wave. Vous serez redirigé hors de l’application.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final payment = _payment;
    final expiresAt = payment?.localReservationExpiresAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          if (payment != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Paiement', payment.paymentReference),
            if (expiresAt != null)
              _buildDetailRow(
                  'Réservation valide jusqu’à', _formatDateTime(expiresAt)),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ReservationDetail? reservation) {
    final payment = _payment;
    final canStart = reservation != null && reservation.isPayable;
    final canOpenWave = payment?.canOpenWave == true;
    final canCheckStatus = payment?.canCheckStatus == true;

    if (payment?.isSuccess == true) {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AccueilScreen()),
              (route) => false,
            );
          },
          style: _primaryButtonStyle(),
          child: const Text(
            'CONTINUER',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isBusy || !canStart
                ? null
                : canOpenWave
                    ? () => _openWaveUrl(payment!.wave!.waveLaunchUrl!)
                    : _startWavePayment,
            style: _primaryButtonStyle(),
            child: _isCreatingCheckout
                ? const _ButtonLoader(label: 'INITIALISATION...')
                : Text(
                    canOpenWave ? 'ROUVRIR WAVE' : 'PAYER AVEC WAVE',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (canCheckStatus) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: _isBusy ? null : _checkPaymentStatus,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F056B),
                side: const BorderSide(color: Color(0xFF0F056B), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCheckingStatus
                  ? const _ButtonLoader(label: 'VÉRIFICATION...')
                  : const Text(
                      'J’AI TERMINÉ LE PAIEMENT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEFD807),
      foregroundColor: Colors.black,
      disabledBackgroundColor: Colors.grey[300],
      disabledForegroundColor: Colors.grey[600],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _ButtonLoader extends StatelessWidget {
  final String label;

  const _ButtonLoader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
