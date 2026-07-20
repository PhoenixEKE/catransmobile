import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/admin_users_api_service.dart';

void main() {
  group('admin users service contract helpers', () {
    test('list query keeps filters and clamps pagination', () {
      final query = buildAdminUsersQueryParameters(
        query: '  aya  ',
        role: 'cashier',
        stationId: ' station-1 ',
        counterId: ' counter-1 ',
        isActive: false,
        ordering: ' lastname ',
        page: -4,
        pageSize: 250,
      );

      expect(query, containsPair('q', 'aya'));
      expect(query, containsPair('role', 'cashier'));
      expect(query, containsPair('station_id', 'station-1'));
      expect(query, containsPair('counter_id', 'counter-1'));
      expect(query, containsPair('is_active', false));
      expect(query, containsPair('ordering', 'lastname'));
      expect(query, containsPair('page', 1));
      expect(query, containsPair('page_size', 100));
    });

    test('create request sends backend field names including password', () {
      const request = AdminInternalUserCreateRequest(
        email: 'cashier@catrans.test',
        phoneNumber: '+2250101010101',
        lastname: 'Koffi',
        firstname: 'Aya',
        role: 'cashier',
        password: 'Admin@1234',
        stationId: 'station-1',
        counterId: 'counter-1',
      );

      expect(request.toJson(), {
        'email': 'cashier@catrans.test',
        'phone_number': '+2250101010101',
        'lastname': 'Koffi',
        'firstname': 'Aya',
        'role': 'cashier',
        'password': 'Admin@1234',
        'station_id': 'station-1',
        'counter_id': 'counter-1',
      });
    });

    test('role options parse station and counter rules', () {
      final role = AdminInternalRoleOption.fromJson({
        'code': 'cashier',
        'label': 'Guichetier',
        'scopes': ['station.sales.cash'],
        'requires_station': true,
        'requires_counter': true,
        'allows_station': true,
        'allows_counter': true,
      });

      expect(role.value, 'cashier');
      expect(role.requiresStation, isTrue);
      expect(role.requiresCounter, isTrue);
      expect(role.allowsStation, isTrue);
      expect(role.allowsCounter, isTrue);
    });

    test('structured DRF field errors expose the field name', () {
      final error = StructuredApiError.fromException(ApiException(
        message: 'Validation impossible.',
        statusCode: 400,
        details: {
          'email': ['Adresse email déjà utilisée.']
        },
      ));

      expect(error.field, 'email');
      expect(error.userMessage, 'Adresse email déjà utilisée.');
    });
  });
}
