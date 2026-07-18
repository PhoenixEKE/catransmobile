import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/station/reports/station_report_common.dart';
import 'package:catrans_app/screens/staff/reports/station_reports_ui_helpers.dart';

void main() {
  group('station reports UI helpers', () {
    test('formats status labels without rigid enums', () {
      expect(stationReportStatusLabel('pending', ''), 'En attente');
      expect(stationReportStatusLabel('unknown_status', ''), 'unknown_status');
      expect(stationReportStatusLabel('pending', 'À traiter'), 'À traiter');
    });

    test('formats dates and amounts', () {
      final date = DateTime.utc(2026, 7, 18, 10, 5);
      expect(formatStationReportDate(date), contains('18/07/2026'));
      expect(formatStationReportDateTime(date), contains('18/07/2026'));
      expect(formatStationReportAmount('7000.00', 'XOF'), '7000.00 XOF');
      expect(formatStationReportAmount('', ''), '-');
    });

    test('formats null seat and eligibility messages', () {
      expect(formatStationReportSeat(null), 'Sans siège attribué');
      expect(formatStationReportSeat(12), 'Siège 12');
      expect(
        stationReportEligibilityMessage(
          const StationReportEligibility(isEligible: true),
        ),
        'Demande éligible au traitement',
      );
      expect(
        stationReportEligibilityMessage(
          const StationReportEligibility(
            isEligible: false,
            blockingMessage: 'Ticket déjà utilisé.',
          ),
        ),
        'Ticket déjà utilisé.',
      );
      expect(
        stationReportEligibilityMessage(
          const StationReportEligibility.unknown(),
        ),
        'Éligibilité non disponible',
      );
    });
  });
}
