import 'package:catrans_app/models/station/reports/station_report_common.dart';

String stationReportStatusLabel(String status, String fallback) {
  final trimmedFallback = fallback.trim();
  if (trimmedFallback.isNotEmpty) return trimmedFallback;

  return switch (status) {
    'pending' => 'En attente',
    'approved' => 'Approuvé',
    'rejected' => 'Rejeté',
    'applied' => 'Appliqué',
    'cancelled' => 'Annulé',
    _ => status.trim().isEmpty ? 'Statut inconnu' : status,
  };
}

String stationReportStatusTone(String status) {
  return switch (status) {
    'pending' => 'warning',
    'approved' => 'info',
    'applied' => 'success',
    'rejected' || 'cancelled' => 'danger',
    _ => 'neutral',
  };
}

String formatStationReportDate(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year.toString().padLeft(4, '0')}';
}

String formatStationReportDateTime(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  return '${formatStationReportDate(local)} à '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String formatStationReportSeat(int? seatNumber) {
  if (seatNumber == null) return 'Sans siège attribué';
  return 'Siège $seatNumber';
}

String stationReportEligibilityMessage(StationReportEligibility eligibility) {
  if (eligibility.isEligible) return 'Demande éligible au traitement';
  final message = eligibility.blockingMessage?.trim();
  if (message != null && message.isNotEmpty) return message;
  return 'Éligibilité non disponible';
}

String formatStationReportAmount(String amount, String currency) {
  final cleanAmount = amount.trim();
  final cleanCurrency = currency.trim();
  if (cleanAmount.isEmpty && cleanCurrency.isEmpty) return '-';
  return '$cleanAmount $cleanCurrency'.trim();
}
