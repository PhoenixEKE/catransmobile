import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_counter_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';

void main() {
  group('admin transport base models', () {
    test('parses company and serializes nullable patch fields', () {
      final company = AdminCompany.fromJson({
        'id': 'company-1',
        'name': 'CA TRANS',
        'code': null,
        'customer_service_phone': '+2250101010101',
        'is_active': true,
        'created_at': '2026-07-20T08:00:00Z',
        'updated_at': '2026-07-20T09:00:00Z',
      });

      expect(company.id, 'company-1');
      expect(company.code, isNull);
      expect(company.customerServicePhone, '+2250101010101');

      const create = AdminCompanyCreateRequest(
        name: ' CA TRANS ',
        code: ' ct ',
        customerServicePhone: ' ',
      );
      expect(create.toJson(), {'name': 'CA TRANS', 'code': 'ct'});

      const absent = AdminCompanyUpdateRequest(name: 'Nouvelle compagnie');
      expect(absent.toJson().containsKey('code'), isFalse);

      const cleared = AdminCompanyUpdateRequest(
        code: AdminTransportPatchField.clear(),
      );
      expect(cleared.toJson(), {'code': null});

      const changed = AdminCompanyUpdateRequest(
        code: AdminTransportPatchField.value('CAT'),
      );
      expect(changed.toJson(), {'code': 'CAT'});
    });

    test('parses city and does not calculate normalized name locally', () {
      final city = AdminCity.fromJson({
        'id': 'city-1',
        'name': 'Yopougon',
        'normalized_name': 'yopougon',
        'country': "Côte d'Ivoire",
        'is_active': true,
        'created_at': '2026-07-20T08:00:00Z',
        'updated_at': '2026-07-20T09:00:00Z',
      });

      expect(city.normalizedName, 'yopougon');
      expect(
        const AdminCityUpdateRequest(country: ' CI ').toJson(),
        {'country': 'CI'},
      );
    });

    test('parses station with typed company and nullable city refs', () {
      final station = AdminStation.fromJson(_stationJson(city: null));

      expect(station.company.name, 'CA TRANS');
      expect(station.city, isNull);
      expect(station.cityNameSnapshot, 'Abidjan');

      const create = AdminStationCreateRequest(
        name: ' Gare Yopougon ',
        companyId: 'company-1',
        cityId: 'city-1',
        code: ' yop ',
      );
      expect(create.toJson()['company_id'], 'company-1');
      expect(create.toJson()['city_id'], 'city-1');
      expect(create.toJson()['code'], 'yop');

      const update = AdminStationUpdateRequest(
        cityId: AdminTransportPatchField.clear(),
        phoneLine: AdminTransportPatchField.value('+2250101010101'),
      );
      expect(update.toJson()['city_id'], isNull);
      expect(update.toJson()['phone_line'], '+2250101010101');
      expect(update.toJson().containsKey('code'), isFalse);
    });

    test('parses counter without sending station_id in body', () {
      final counter = AdminStationCounter.fromJson({
        'id': 'counter-1',
        'station': _stationRefJson(),
        'code': 'A1',
        'label': 'Guichet A1',
        'is_active': true,
        'created_at': '2026-07-20T08:00:00Z',
        'updated_at': '2026-07-20T09:00:00Z',
      });

      expect(counter.station.cityName, 'Yopougon');
      expect(
        const AdminStationCounterCreateRequest(
          code: ' a1 ',
          label: ' Principal ',
        ).toJson(),
        {'code': 'a1', 'label': 'Principal'},
      );
    });

    test('parses service class and serializes optional fields', () {
      final serviceClass = AdminServiceClass.fromJson({
        'id': 'class-1',
        'code': 'PRESTIGE',
        'name': 'Prestige',
        'default_loyalty_points': '10',
        'reward_threshold_points': 100,
        'allows_seat_selection': true,
        'is_active': true,
        'created_at': '2026-07-20T08:00:00Z',
        'updated_at': '2026-07-20T09:00:00Z',
      });

      expect(serviceClass.defaultLoyaltyPoints, 10);
      expect(serviceClass.allowsSeatSelection, isTrue);
      expect(
        const AdminServiceClassUpdateRequest(
          name: ' Prestige + ',
          allowsSeatSelection: false,
        ).toJson(),
        {'name': 'Prestige +', 'allows_seat_selection': false},
      );
    });
  });
}

Map<String, dynamic> _stationJson({Object? city = const {}}) {
  return {
    'id': 'station-1',
    'name': 'Gare Yopougon',
    'normalized_name': 'gare-yopougon',
    'code': 'YOP',
    'phone_line': null,
    'representative': null,
    'city_name_snapshot': 'Abidjan',
    'city_name': 'Yopougon',
    'company': {
      'id': 'company-1',
      'name': 'CA TRANS',
      'code': 'CAT',
      'is_active': true,
    },
    'city': city is Map && city.isEmpty
        ? {
            'id': 'city-1',
            'name': 'Yopougon',
            'country': "Côte d'Ivoire",
            'is_active': true,
          }
        : city,
    'is_active': true,
    'created_at': '2026-07-20T08:00:00Z',
    'updated_at': '2026-07-20T09:00:00Z',
  };
}

Map<String, dynamic> _stationRefJson() {
  return {
    'id': 'station-1',
    'name': 'Gare Yopougon',
    'code': 'YOP',
    'city_name': 'Yopougon',
    'is_active': true,
  };
}
