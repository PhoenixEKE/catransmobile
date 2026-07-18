import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/station/reports/station_cancellation_detail.dart';
import 'package:catrans_app/models/station/reports/station_reports_page.dart';
import 'package:catrans_app/models/station/reports/station_reservation_change_detail.dart';
import 'package:catrans_app/services/api/station_reports_api_service.dart';

void main() {
  group('Station reports models', () {
    test('parse paginated reservation changes with safe defaults', () {
      final page = StationReservationChangesPage.fromJson({
        'count': '1',
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 'change-1',
            'reference': 'REP-001',
            'status': 'new_backend_value',
            'status_label': 'Valeur inconnue',
            'change_type': 'departure_change',
            'change_type_label': 'Report',
            'requested_at': '2026-07-18T10:00:00Z',
            'reservation_id': 'reservation-1',
            'reservation_reference': 'RES-001',
            'customer_name': 'Aya Kouame',
            'customer_phone': '+2250102030405',
            'items_count': 2,
          },
        ],
      });

      expect(page.count, 1);
      expect(page.results.single.status, 'new_backend_value');
      expect(page.results.single.availableActions.canApprove, isFalse);
      expect(page.results.single.eligibility.isEligible, isFalse);
    });

    test('parse economy report detail without seats', () {
      final detail = StationReservationChangeDetail.fromJson({
        'id': 'change-1',
        'reference': 'REP-001',
        'status': 'pending',
        'status_label': 'En attente',
        'change_type': 'departure_change',
        'change_type_label': 'Report',
        'reservation_id': 'reservation-1',
        'reservation_reference': 'RES-001',
        'customer_phone': '+2250102030405',
        'items_count': 1,
        'available_actions': {'can_approve': true},
        'eligibility': {'is_eligible': true},
        'items': [
          {
            'id': 'item-1',
            'reservation_item_id': 'reservation-item-1',
            'traveler': {'lastname': 'Kouame', 'firstname': 'Aya'},
            'old_seat_number': null,
            'new_seat_number': null,
            'old_unit_price': '7000.00',
            'new_unit_price': '7000.00',
            'fare_difference': '0.00',
          },
        ],
        'flags': {},
      });

      expect(detail.items.single.oldSeatNumber, isNull);
      expect(detail.items.single.newSeatNumber, isNull);
      expect(detail.availableActions.canApprove, isTrue);
      expect(detail.flags.refundAutomatic, isFalse);
    });

    test('parse prestige report detail with explicit seats', () {
      final detail = StationReservationChangeDetail.fromJson({
        'id': 'change-2',
        'reference': 'REP-002',
        'status': 'pending',
        'status_label': 'En attente',
        'change_type': 'departure_change',
        'change_type_label': 'Report',
        'reservation_id': 'reservation-2',
        'reservation_reference': 'RES-002',
        'customer_phone': '+2250102030405',
        'items_count': 1,
        'items': [
          {
            'id': 'item-2',
            'reservation_item_id': 'reservation-item-2',
            'traveler': {'lastname': 'Kouame', 'firstname': 'Aya'},
            'old_seat_number': 12,
            'new_seat_number': 13,
            'old_ticket': {
              'id': 'ticket-1',
              'reference': 'TCK-001',
              'status': 'issued',
            },
            'old_unit_price': '9000.00',
            'new_unit_price': '9000.00',
            'fare_difference': '0.00',
          },
        ],
      });

      expect(detail.items.single.oldSeatNumber, 12);
      expect(detail.items.single.newSeatNumber, 13);
      expect(detail.items.single.oldTicket?.reference, 'TCK-001');
    });

    test('parse cancellation page and detail with payments', () {
      final page = StationCancellationsPage.fromJson({
        'count': 1,
        'results': [
          {
            'id': 'cancellation-1',
            'reference': 'ANN-001',
            'status': 'pending',
            'status_label': 'En attente',
            'channel': 'client',
            'channel_label': 'Client',
            'reservation_id': 'reservation-1',
            'reservation_reference': 'RES-001',
            'customer_phone': '+2250102030405',
            'travelers_count': '2',
            'tickets_count': 2,
            'total_amount': '14000.00',
            'currency': 'XOF',
          },
        ],
      });

      expect(page.results.single.travelersCount, 2);
      expect(page.results.single.displayAmount, '14000.00 XOF');

      final detail = StationCancellationDetail.fromJson({
        'id': 'cancellation-1',
        'reference': 'ANN-001',
        'status': 'pending',
        'status_label': 'En attente',
        'channel': 'client',
        'channel_label': 'Client',
        'reservation_id': 'reservation-1',
        'reservation_reference': 'RES-001',
        'customer_phone': '+2250102030405',
        'travelers_count': 2,
        'tickets_count': 2,
        'total_amount': '14000.00',
        'currency': 'XOF',
        'tickets': {'total': 2, 'issued': 2, 'used': 0, 'cancelled': 0},
        'payments': [
          {
            'id': 'payment-1',
            'reference': 'PAY-001',
            'status': 'success',
            'status_label': 'Payé',
            'amount': '14000.00',
            'currency': 'XOF',
            'provider': 'wave',
            'paid_at': '2026-07-18T10:00:00Z',
          },
        ],
        'consequences': {
          'cancellation_scope': 'full_reservation',
          'tickets_to_cancel': 2,
        },
      });

      expect(detail.tickets.issued, 2);
      expect(detail.payments.single.provider, 'wave');
      expect(detail.consequences.refundAutomatic, isFalse);
    });
  });

  group('StationReportsApiService helpers', () {
    test('build query params trims and omits empty values', () {
      final query = buildStationReportsQueryParameters(
        page: 0,
        pageSize: 250,
        status: ' all ',
        search: '  RES-001  ',
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 18),
      );

      expect(query['page'], 1);
      expect(query['page_size'], 100);
      expect(query.containsKey('status'), isFalse);
      expect(query['search'], 'RES-001');
      expect(query['date_from'], '2026-07-01');
      expect(query['date_to'], '2026-07-18');
      expect(query.values.any((value) => value == null), isFalse);
    });

    test('build distinct reject payloads', () {
      expect(buildStationReportRejectPayload(' Motif ')['reason'], 'Motif');
      expect(
        buildStationCancellationRejectPayload(' Motif ')['rejection_reason'],
        'Motif',
      );
      expect(() => buildStationReportRejectPayload(' '), throwsArgumentError);
      expect(
        () => buildStationCancellationRejectPayload(' '),
        throwsArgumentError,
      );
    });
  });
}
