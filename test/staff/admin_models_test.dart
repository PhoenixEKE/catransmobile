import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/admin/station_cash_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';

void main() {
  group('staff admin models', () {
    test('parses paged result and minimal refs', () {
      final page = PagedResult<StaffRef>.fromJson({
        'count': '1',
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 'station-1',
            'code': 'YOP',
            'name': 'Yopougon',
            'is_active': true
          },
        ],
      }, StaffRef.fromJson);

      expect(page.count, 1);
      expect(page.results.single.label, 'YOP - Yopougon');
      expect(page.hasNext, isFalse);
    });

    test('parses non paginated list response', () {
      final page = PagedResult<StaffRef>.fromJson([
        {'id': 'city-1', 'name': 'Bouaké'},
      ], StaffRef.fromJson);

      expect(page.count, 1);
      expect(page.results.single.name, 'Bouaké');
    });

    test('parses structured backend errors and DRF fallback', () {
      final structured = StructuredApiError.fromPayload({
        'code': 'station_counter_required',
        'detail': 'Guichet requis.',
        'field': null,
      }, statusCode: 400);

      expect(structured.code, 'station_counter_required');
      expect(structured.userMessage, 'Guichet requis.');

      final drf = StructuredApiError.fromException(ApiException(
        message: 'Erreur',
        statusCode: 400,
        details: {
          'email': ['Adresse email déjà utilisée.']
        },
      ));

      expect(drf.userMessage, 'Adresse email déjà utilisée.');
    });

    test('parses admin internal user response', () {
      final user = AdminInternalUserDetail.fromJson({
        'id': 'user-1',
        'email': 'director@catrans.test',
        'phone_number': '+2250101010101',
        'lastname': 'Kouame',
        'firstname': 'Aya',
        'is_active': true,
        'internal_profile': {
          'role': 'director',
          'role_label': 'Direction',
          'station': {'id': 'station-1', 'name': 'Yopougon'},
        },
        'scopes': ['admin.users.read'],
      });

      expect(user.fullName, 'Aya Kouame');
      expect(user.role, 'director');
      expect(user.station?.name, 'Yopougon');
      expect(user.scopes, contains('admin.users.read'));
    });

    test('parses cash responses', () {
      final sale = StationCashSaleCreateResponse.fromJson({
        'reservation': {
          'id': 'reservation-1',
          'reference': 'RES-001',
          'status': 'pending_payment',
          'total_amount': '7000.00',
          'currency': 'XOF',
        },
      });

      expect(sale.reservationId, 'reservation-1');
      expect(sale.currency, 'XOF');

      final confirm = StationCashConfirmResponse.fromJson({
        'reservation_id': 'reservation-1',
        'payment_id': 'payment-1',
        'status': 'confirmed',
      });

      expect(confirm.paymentId, 'payment-1');
    });
  });
}
