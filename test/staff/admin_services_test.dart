import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/admin/station_cash_models.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/services/api/staff/admin/admin_transport_api_service.dart';
import 'package:catrans_app/services/api/staff/admin/admin_users_api_service.dart';

void main() {
  group('admin service helpers', () {
    test('AdminUsersApiService query omits empty values', () {
      final query = buildAdminUsersQueryParameters(
        query: '  aya  ',
        role: ' ',
        stationId: 'station-1',
        isActive: true,
        page: 0,
        pageSize: 250,
      );

      expect(query['q'], 'aya');
      expect(query.containsKey('role'), isFalse);
      expect(query['station_id'], 'station-1');
      expect(query['is_active'], isTrue);
      expect(query['page'], 1);
      expect(query['page_size'], 100);
    });

    test('AdminTransportApiService query keeps supported params only', () {
      final query = buildAdminTransportQueryParameters(
        query: ' Yop ',
        isActive: false,
        ordering: ' name ',
        extra: {'country': 'CI'},
      );

      expect(query['q'], 'Yop');
      expect(query['is_active'], isFalse);
      expect(query['ordering'], 'name');
      expect(query['country'], 'CI');
    });

    test('AdminOperationsApiService query keeps status extra', () {
      final query = buildAdminOperationsQueryParameters(
        query: ' DEP ',
        extra: {'status': 'open'},
      );

      expect(query['q'], 'DEP');
      expect(query['status'], 'open');
    });

    test('admin user requests serialize backend field names', () {
      const create = AdminInternalUserCreateRequest(
        email: 'agent@catrans.test',
        phoneNumber: '+2250101010101',
        lastname: 'Koffi',
        firstname: 'Jean',
        role: 'cashier',
        password: 'Admin@1234',
        stationId: 'station-1',
        counterId: 'counter-1',
      );

      expect(create.toJson()['phone_number'], '+2250101010101');
      expect(create.toJson()['password'], 'Admin@1234');
      expect(create.toJson()['station_id'], 'station-1');
    });

    test('cash request never sends technical payment secrets', () {
      const request = StationCashSaleCreateRequest(
        departureId: 'departure-1',
        serviceClassCode: 'ECONOMIE',
        items: [StationCashSaleItemRequest(travelerLastname: 'Kouadio')],
        note: ' Paiement cash ',
      );

      final json = request.toJson();
      expect(json['departure_id'], 'departure-1');
      expect(json['service_class_code'], 'ECONOMIE');
      expect(json['note'], 'Paiement cash');
      expect(json.containsKey('token'), isFalse);
    });
  });
}
