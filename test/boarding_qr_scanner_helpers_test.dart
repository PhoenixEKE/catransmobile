import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/station/station_ticket_validation.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_qr_scanner_helpers.dart';

StationTicketValidation validation({
  required String status,
  String? resultMessage,
  String statusLabel = '',
}) {
  return StationTicketValidation(
    id: 'validation-id',
    status: status,
    statusLabel: statusLabel,
    channel: 'station_agent',
    channelLabel: 'Agent gare',
    resultMessage: resultMessage,
  );
}

void main() {
  test('normalizes scanned QR values', () {
    expect(normalizeScannedQrValue('  token-value  '), 'token-value');
    expect(normalizeScannedQrValue('   '), isNull);
    expect(normalizeScannedQrValue(null), isNull);
  });

  test('scanner availability follows V1 platform policy', () {
    expect(
      isBoardingQrScannerSupported(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      isBoardingQrScannerSupported(isWeb: false, platform: TargetPlatform.iOS),
      isTrue,
    );
    expect(
      isBoardingQrScannerSupported(
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      isFalse,
    );
    expect(
      isBoardingQrScannerSupported(
        isWeb: false,
        platform: TargetPlatform.linux,
      ),
      isFalse,
    );
  });

  test('scan gate ignores empty and processing events', () {
    final gate = BoardingQrScanGate();
    final now = DateTime(2026, 7, 19, 10);

    expect(gate.tryStartProcessing('', now), isFalse);
    expect(gate.tryStartProcessing('token', now), isTrue);
    expect(gate.tryStartProcessing('other', now), isFalse);

    gate.finishProcessing();
    expect(
        gate.tryStartProcessing('token', now.add(const Duration(seconds: 1))),
        isFalse);
    expect(
        gate.tryStartProcessing('token', now.add(const Duration(seconds: 3))),
        isTrue);
  });

  test('maps accepted status', () {
    final presentation =
        presentationForValidation(validation(status: 'accepted'));
    expect(presentation.isSuccess, isTrue);
    expect(presentation.title, 'Billet validé');
  });

  test('maps refused statuses without exposing tokens', () {
    const statuses = {
      'duplicate': 'Ce billet a déjà été validé.',
      'cancelled_ticket': 'Ce billet a été annulé et ne peut pas être utilisé.',
      'expired_ticket': 'Ce billet a expiré.',
      'invalidated_ticket':
          'Ce billet a été invalidé. Utilisez le billet le plus récent.',
      'legacy_ticket':
          'Ce billet ancien n’est pas validable avec le scanner V1.',
      'wrong_departure': 'Ce billet appartient à un autre départ.',
      'invalid_token':
          'QR inconnu ou devenu invalide. Vérifiez que le voyageur présente son billet le plus récent.',
    };

    for (final entry in statuses.entries) {
      final presentation =
          presentationForValidation(validation(status: entry.key));
      expect(presentation.isSuccess, isFalse);
      expect(presentation.message, entry.value);
      expect(presentation.message.contains('validation_token'), isFalse);
      expect(presentation.message.contains('scanned_token'), isFalse);
    }
  });

  test('uses safe backend message for rejected status', () {
    final presentation = presentationForValidation(
      validation(
          status: 'rejected', resultMessage: 'Ce départ n’est plus ouvert.'),
    );
    expect(presentation.message, 'Ce départ n’est plus ouvert.');
  });

  test('hides technical backend messages', () {
    final presentation = presentationForValidation(
      validation(
          status: 'rejected',
          resultMessage: 'Traceback validation_token secret'),
    );
    expect(presentation.message, 'Le billet n’a pas pu être validé.');
  });

  test('maps unknown status', () {
    final presentation = presentationForValidation(
      validation(status: 'future_status', statusLabel: 'Statut futur'),
    );
    expect(presentation.isSuccess, isFalse);
    expect(presentation.title, 'Statut futur');
  });

  test('maps HTTP errors', () {
    expect(httpScannerErrorMessage(400, 'bad'),
        'Le QR ou les informations du départ sont invalides.');
    expect(httpScannerErrorMessage(401, 'auth'),
        'Votre session a expiré. Veuillez vous reconnecter.');
    expect(httpScannerErrorMessage(403, 'forbidden'),
        'Vous n’êtes pas autorisé à valider des billets.');
    expect(httpScannerErrorMessage(404, 'missing'),
        'Ce départ n’est plus accessible.');
    expect(httpScannerErrorMessage(409, 'conflict'),
        'Le billet vient d’être traité. Les données vont être actualisées.');
    expect(httpScannerErrorMessage(null, 'network'),
        'Impossible de contacter le serveur. Vérifiez la connexion puis réessayez.');
  });
}
