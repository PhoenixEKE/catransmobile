import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/station/station_reservation_list.dart';
import 'package:catrans_app/screens/staff/counter/counter_search_screen.dart';
import 'package:catrans_app/services/api/station_counter_api_service.dart';
import 'package:catrans_app/services/auth_service.dart';

import '../support/fake_auth.dart';

void main() {
  testWidgets('station reservations entry keeps the cash sale tab for admins',
      (tester) async {
    final authService = AuthService(
      authApiService: FakeAuthApiService()..userOnMe = _adminUser,
      tokenStorage: FakeTokenStorage()..seedAccessToken('admin-token'),
    );
    await authService.loadUser();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: authService,
        child: MaterialApp(
          home: Scaffold(
            body: CounterSearchScreen(
              supervisionMode: true,
              stationId: 'station-1',
              apiService: _FakeStationCounterApiService(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Réservations'), findsWidgets);
    expect(find.text('Recherche'), findsOneWidget);
    expect(find.text('Vente cash'), findsOneWidget);
  });
}

final _adminUser = User(
  id: 'admin-1',
  lastname: 'Admin',
  firstname: 'Fusion',
  phoneNumber: '+2250101010101',
  email: 'admin@catrans.test',
  userType: UserType.staff,
  internalProfile: const InternalProfile(
    id: 'profile-admin',
    role: InternalRole.admin,
    roleLabel: 'Admin',
  ),
  scopes: const [
    StaffPermissions.stationReservationsRead,
    StaffPermissions.stationReservationsSearch,
    StaffPermissions.stationTicketsPrint,
    StaffPermissions.stationTicketsRead,
    StaffPermissions.stationSalesCash,
    StaffPermissions.stationAllRead,
    StaffPermissions.stationDeparturesRead,
  ],
);

class _FakeStationCounterApiService extends StationCounterApiService {
  _FakeStationCounterApiService()
      : super(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1/')),
          ),
        );

  @override
  Future<StationReservationListResponse> listReservations({
    String? query,
    String? status,
    String? paymentStatus,
    String? ticketStatus,
    String? dateFrom,
    String? dateTo,
    String? serviceClass,
    String? stationId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return const StationReservationListResponse(count: 0, results: []);
  }
}
