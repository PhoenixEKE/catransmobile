import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:catrans_app/models/station/station_ticket_validation.dart';

String? normalizeScannedQrValue(String? rawValue) {
  final value = rawValue?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

bool isBoardingQrScannerSupported({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return false;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

bool get isBoardingQrScannerSupportedOnCurrentPlatform {
  return isBoardingQrScannerSupported(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
  );
}

bool shouldRefreshBoardingAfterValidation(StationTicketValidation validation) {
  return validation.status.trim().isNotEmpty;
}

class BoardingQrScanGate {
  bool _isProcessing = false;
  String? _lastToken;
  DateTime? _lastScanAt;

  bool get isProcessing => _isProcessing;

  bool tryStartProcessing(String token, DateTime now) {
    final normalizedToken = normalizeScannedQrValue(token);
    if (normalizedToken == null || _isProcessing) return false;

    if (_lastToken == normalizedToken && _lastScanAt != null) {
      final elapsed = now.difference(_lastScanAt!);
      if (elapsed < const Duration(seconds: 2)) return false;
    }

    _isProcessing = true;
    _lastToken = normalizedToken;
    _lastScanAt = now;
    return true;
  }

  void finishProcessing() {
    _isProcessing = false;
  }

  void resetForNextScan() {
    _isProcessing = false;
    _lastToken = null;
    _lastScanAt = null;
  }
}

class BoardingQrValidationPresentation {
  final bool isSuccess;
  final String title;
  final String message;
  final IconData icon;

  const BoardingQrValidationPresentation({
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.icon,
  });
}

BoardingQrValidationPresentation presentationForValidation(
  StationTicketValidation validation,
) {
  switch (validation.status) {
    case 'accepted':
      return const BoardingQrValidationPresentation(
        isSuccess: true,
        title: 'Billet validé',
        message: 'Le voyageur peut embarquer sur ce départ.',
        icon: Icons.check_circle,
      );
    case 'duplicate':
      return const BoardingQrValidationPresentation(
        isSuccess: false,
        title: 'Billet déjà validé',
        message: 'Ce billet a déjà été validé.',
        icon: Icons.history,
      );
    case 'cancelled_ticket':
      return const BoardingQrValidationPresentation(
        isSuccess: false,
        title: 'Billet annulé',
        message: 'Ce billet a été annulé et ne peut pas être utilisé.',
        icon: Icons.cancel,
      );
    case 'expired_ticket':
      return const BoardingQrValidationPresentation(
        isSuccess: false,
        title: 'Billet expiré',
        message: 'Ce billet a expiré.',
        icon: Icons.timer_off,
      );
    case 'invalidated_ticket':
      return const BoardingQrValidationPresentation(
        isSuccess: false,
        title: 'Billet invalidé',
        message: 'Ce billet a été invalidé. Utilisez le billet le plus récent.',
        icon: Icons.report_gmailerrorred,
      );
    case 'legacy_ticket':
      return const BoardingQrValidationPresentation(
        isSuccess: false,
        title: 'Billet ancien',
        message: 'Ce billet ancien n’est pas validable avec le scanner V1.',
        icon: Icons.inventory_2_outlined,
      );
    case 'wrong_departure':
      return const BoardingQrValidationPresentation(
        isSuccess: false,
        title: 'Mauvais départ',
        message: 'Ce billet appartient à un autre départ.',
        icon: Icons.alt_route,
      );
    case 'invalid_token':
      return const BoardingQrValidationPresentation(
        isSuccess: false,
        title: 'QR invalide',
        message:
            'QR inconnu ou devenu invalide. Vérifiez que le voyageur présente son billet le plus récent.',
        icon: Icons.qr_code_2,
      );
    case 'rejected':
      return BoardingQrValidationPresentation(
        isSuccess: false,
        title: 'Validation refusée',
        message: _safeBackendMessage(validation.resultMessage) ??
            'Le billet n’a pas pu être validé.',
        icon: Icons.error_outline,
      );
    default:
      return BoardingQrValidationPresentation(
        isSuccess: false,
        title: validation.statusLabel.trim().isNotEmpty
            ? validation.statusLabel
            : 'Validation refusée',
        message: _safeBackendMessage(validation.resultMessage) ??
            'Le billet n’a pas pu être validé.',
        icon: Icons.error_outline,
      );
  }
}

String httpScannerErrorMessage(int? statusCode, String fallbackMessage) {
  switch (statusCode) {
    case 400:
      return 'Le QR ou les informations du départ sont invalides.';
    case 401:
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    case 403:
      return 'Vous n’êtes pas autorisé à valider des billets.';
    case 404:
      return 'Ce départ n’est plus accessible.';
    case 409:
      return 'Le billet vient d’être traité. Les données vont être actualisées.';
    case null:
      return 'Impossible de contacter le serveur. Vérifiez la connexion puis réessayez.';
    default:
      return _safeBackendMessage(fallbackMessage) ??
          'Le billet n’a pas pu être validé.';
  }
}

String? _safeBackendMessage(String? message) {
  final value = message?.trim();
  if (value == null || value.isEmpty) return null;

  final lower = value.toLowerCase();
  if (lower.contains('<html') ||
      lower.contains('traceback') ||
      lower.contains('exception') ||
      lower.contains('validation' '_token') ||
      lower.contains('scanned' '_token')) {
    return null;
  }

  return value;
}
