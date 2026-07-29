import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/reports/station_report_common.dart';
import 'package:catrans_app/screens/staff/reports/station_report_actions.dart';
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
    test(
        'shows mutation actions only when backend action and eligibility allow it',
        () {
      const actions = StationReportAvailableActions(
        canApprove: true,
        canReject: false,
        canApply: true,
        canViewReservation: true,
      );
      const eligible = StationReportEligibility(isEligible: true);
      const blocked = StationReportEligibility(
        isEligible: false,
        blockingCode: 'TICKET_ALREADY_USED',
      );

      expect(
        canShowStationReportAction(
          availableActions: actions,
          eligibility: eligible,
          action: StationReportActionKind.approve,
        ),
        isTrue,
      );
      expect(
        canShowStationReportAction(
          availableActions: actions,
          eligibility: eligible,
          action: StationReportActionKind.reject,
        ),
        isFalse,
      );
      expect(
        canShowStationReportAction(
          availableActions: actions,
          eligibility: blocked,
          action: StationReportActionKind.approve,
        ),
        isFalse,
      );
      expect(
        visibleStationReportActions(
          availableActions: actions,
          eligibility: eligible,
        ),
        [StationReportActionKind.approve, StationReportActionKind.apply],
      );
    });

    test('trims rejection reason and rejects empty text', () {
      expect(normalizeStationReportRejectionReason('  Motif métier  '),
          'Motif métier');
      expect(normalizeStationReportRejectionReason('   '), isEmpty);
    });

    test('maps business and HTTP errors to readable messages', () {
      expect(
        stationReportMutationErrorMessage(
          ApiException(
            message: 'Invalid',
            statusCode: 400,
            details: {'code': 'TICKET_ALREADY_USED'},
          ),
        ),
        'Cette demande ne peut plus être traitée car un ticket a déjà été utilisé.',
      );
      expect(
        stationReportMutationErrorMessage(
          ApiException(message: 'Forbidden', statusCode: 403),
        ),
        'Vous n’êtes pas autorisé à traiter cette demande.',
      );
      expect(
        shouldRefreshAfterStationReportMutationError(
          ApiException(
            message: 'Conflict',
            statusCode: 409,
          ),
        ),
        isTrue,
      );
    });

    test('moves to previous page when mutation empties a later page', () {
      expect(
        pageAfterStationReportMutation(currentPage: 3, currentResultCount: 1),
        2,
      );
      expect(
        pageAfterStationReportMutation(currentPage: 1, currentResultCount: 1),
        1,
      );
      expect(
        pageAfterStationReportMutation(currentPage: 2, currentResultCount: 3),
        2,
      );
    });
  });
}
