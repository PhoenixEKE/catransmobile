import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/screens/client/home/accueil_screen.dart';
import 'package:catrans_app/screens/staff/auth/personnel_entry_screen.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departure_generation_dialog.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';
import 'package:catrans_app/screens/staff/shell/staff_shell_screen.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:catrans_app/widgets/staff/staff_sidebar.dart';

import '../support/fake_auth.dart';

void main() {
  group('LOT 6.8HI global stabilization smoke', () {
    testWidgets('/personnel shows the login form when nobody is logged in',
        (tester) async {
      await tester.pumpWidget(_personnelEntry(
        AuthService(
          authApiService: FakeAuthApiService(),
          tokenStorage: FakeTokenStorage(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Espace personnel CA TRANS'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email professionnel'),
          findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
    });

    testWidgets('/personnel blocks a customer account cleanly', (tester) async {
      final api = FakeAuthApiService()..userOnMe = _customerUser();
      final authService = AuthService(
        authApiService: api,
        tokenStorage: FakeTokenStorage()..seedAccessToken('customer-token'),
      );

      await tester.pumpWidget(_personnelEntry(authService));
      await tester.pumpAndSettle();

      expect(find.text('Espace réservé au personnel'), findsOneWidget);
      expect(find.text('Retour à l\'application voyageur'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsOneWidget);
    });

    test('admin initial menu resolves to the admin dashboard', () {
      final user = _internalUser(
        role: InternalRole.admin,
        scopes: const [
          StaffPermissions.adminDashboardRead,
          StaffPermissions.adminUsersRead,
          StaffPermissions.adminTransportRead,
          StaffPermissions.adminOperationsRead,
        ],
      );

      final menuItems = StaffMenuItem.forUser(user);

      expect(resolveInitialStaffMenuId(
        menuItems: menuItems,
        scopes: user.scopes.toSet(),
        role: user.internalProfile?.role,
      ), 'admin_dashboard');
    });

    test('station_manager initial menu resolves to the home dashboard', () {
      final user = _internalUser(
        role: InternalRole.station_manager,
        scopes: const [
          'station.dashboard.read',
          'station.departures.read',
          'station.reservations.read',
          'boarding.manifest.read',
          'station.reports.manage',
        ],
      );

      final menuItems = StaffMenuItem.forUser(user);

      expect(resolveInitialStaffMenuId(
        menuItems: menuItems,
        scopes: user.scopes.toSet(),
        role: user.internalProfile?.role,
      ), 'home');
    });

    test('station_agent initial menu resolves to boarding', () {
      final user = _internalUser(
        role: InternalRole.station_agent,
        scopes: const [
          'station.departures.read',
          'boarding.manifest.read',
          'boarding.validate',
          'boarding.summary.read',
        ],
      );

      final menuItems = StaffMenuItem.forUser(user);

      expect(resolveInitialStaffMenuId(
        menuItems: menuItems,
        scopes: user.scopes.toSet(),
        role: user.internalProfile?.role,
      ), 'boarding');
    });

    test('cashier initial menu resolves to reservation search', () {
      final user = _internalUser(
        role: InternalRole.cashier,
        scopes: const [
          'station.reservations.search',
          'station.tickets.print',
          'station.departures.read',
        ],
      );

      final menuItems = StaffMenuItem.forUser(user);

      expect(resolveInitialStaffMenuId(
        menuItems: menuItems,
        scopes: user.scopes.toSet(),
        role: user.internalProfile?.role,
      ), 'reservation_search');
    });

    test('admin menu exposes the expected internal modules', () {
      final user = _internalUser(
        role: InternalRole.admin,
        scopes: const [
          StaffPermissions.adminDashboardRead,
          StaffPermissions.adminUsersRead,
          StaffPermissions.adminTransportRead,
          StaffPermissions.adminOperationsRead,
        ],
      );

      expect(_ids(StaffMenuItem.forUser(user)), const [
        'home',
        'admin_dashboard',
        'admin_users',
        'admin_transport',
        'admin_operations',
      ]);
    });

    test('station_manager menu exposes the operational modules', () {
      final user = _internalUser(
        role: InternalRole.station_manager,
        scopes: const [
          'station.departures.read',
          'station.reservations.read',
          'boarding.manifest.read',
          'boarding.summary.read',
          'station.reports.manage',
        ],
      );

      expect(_ids(StaffMenuItem.forUser(user)), const [
        'home',
        'departures',
        'station_reservations',
        'boarding',
        'reports',
      ]);
    });

    test('station_agent menu exposes the boarding workflow only', () {
      final user = _internalUser(
        role: InternalRole.station_agent,
        scopes: const [
          'station.departures.read',
          'boarding.manifest.read',
          'boarding.validate',
          'boarding.summary.read',
        ],
      );

      expect(_ids(StaffMenuItem.forUser(user)), const [
        'home',
        'boarding',
      ]);
    });

    test('cashier menu exposes the cash workflow only', () {
      final user = _internalUser(
        role: InternalRole.cashier,
        scopes: const [
          'station.reservations.search',
          'station.tickets.print',
          'station.sales.cash',
          'station.departures.read',
        ],
      );

      expect(_ids(StaffMenuItem.forUser(user)), const [
        'home',
        'reservation_search',
      ]);
    });

    testWidgets('access denied page builds without eager API work',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StaffAccessDeniedPage()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Accès personnel indisponible'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsOneWidget);
    });

    testWidgets('access denied page returns the customer to the traveller app',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: StaffAccessDeniedPage(user: _customerUser())),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Retour à l\'application voyageur'));
      await tester.tap(find.text('Retour à l\'application voyageur'));
      await tester.pumpAndSettle();

      expect(find.byType(AccueilScreen), findsOneWidget);
    });

    testWidgets('access denied logout remains reachable', (tester) async {
      final authService = AuthService(
        authApiService: FakeAuthApiService(),
        tokenStorage: FakeTokenStorage()..seedAccessToken('logout-token'),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: MaterialApp(home: StaffAccessDeniedPage(user: _supportUser())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Se déconnecter'));
      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('shell stays stable at 1440x900', (tester) async {
      await _pumpShell(tester, const Size(1440, 900));

      expect(tester.takeException(), isNull);
      expect(find.byType(StaffSidebar), findsOneWidget);
    });

    testWidgets('shell stays stable at 1024x768', (tester) async {
      await _pumpShell(tester, const Size(1024, 768));

      expect(tester.takeException(), isNull);
      expect(find.byType(StaffSidebar), findsOneWidget);
    });

    testWidgets('shell stays stable at 768x1024', (tester) async {
      await _pumpShell(tester, const Size(768, 1024));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Menu'), findsOneWidget);
    });

    testWidgets('shell stays stable at 390x844', (tester) async {
      await _pumpShell(tester, const Size(390, 844));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Menu'), findsOneWidget);
    });

    testWidgets('shell stays stable at 320x700', (tester) async {
      await _pumpShell(tester, const Size(320, 700));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Menu'), findsOneWidget);
    });

    testWidgets('representative generation dialog fits at 320 px',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showAdminDepartureGenerationDialog(
                        context: context,
                        templates: const [
                          AdminOperationRecord(
                            id: 'template-1',
                            name: 'Bamako · Prestige · 08:00',
                            raw: {
                              'station': {'name': 'Bamako'},
                              'service_class': {'name': 'Prestige'},
                              'departure_time': '08:00',
                            },
                            isActive: true,
                          ),
                        ],
                        previewGeneration: (templateId, request) async {
                          return {
                            'results': [
                              {
                                'departure_date': request.departureDates.first,
                                'valid': true,
                                'already_exists': false,
                              },
                            ],
                          };
                        },
                        generateDepartures: (templateId, request) async {
                          return AdminDepartureGenerationResult(
                            createdCount: request.departureDates.length,
                            existingCount: 0,
                            departures: [
                              AdminDepartureGenerationResultItem(
                                departureDate: request.departureDates.first,
                                created: true,
                                departure: AdminDeparture(
                                  id: 'departure-1',
                                  departureDate: request.departureDates.first,
                                  status: const AdminDepartureStatus(
                                    code: 'scheduled',
                                    label: 'Scheduled',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        isSubmitting: false,
                      );
                    },
                    child: const Text('Open dialog'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Générer des départs'), findsOneWidget);

      await tester.ensureVisible(find.text('Prévisualiser'));
      await tester.tap(find.text('Prévisualiser'));
      await tester.pumpAndSettle();

      expect(find.textContaining('valide'), findsWidgets);
    });

    test('visible staff menu copy does not contain chantier phrasing', () {
      final menuItems = StaffMenuItem.forUser(_internalUser(
        role: InternalRole.admin,
        scopes: const [
          StaffPermissions.adminDashboardRead,
          StaffPermissions.adminUsersRead,
          StaffPermissions.adminTransportRead,
          StaffPermissions.adminOperationsRead,
        ],
      ));

      final copy = menuItems
          .map((item) => '${item.title} ${item.moduleDescription} ${item.nextStep}')
          .join(' ')
          .toLowerCase();

      for (final phrase in const [
        'bientôt disponible',
        'prochain lot',
        'roadmap',
        'sera branché',
        'sera branchée',
        'sera disponible progressivement',
        'lot ',
      ]) {
        expect(copy.contains(phrase), isFalse);
      }
    });
  });
}

Widget _personnelEntry(AuthService authService) {
  return ChangeNotifierProvider<AuthService>.value(
    value: authService,
    child: const MaterialApp(home: PersonnelEntryScreen()),
  );
}

Future<void> _pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final authService = AuthService(
    authApiService: FakeAuthApiService()..userOnMe = _supportUser(),
    tokenStorage: FakeTokenStorage()..seedAccessToken('shell-token'),
  );
  await authService.loadUser();

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: const MaterialApp(home: StaffShellScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _ids(List<StaffMenuItem> items) =>
    items.map((item) => item.id).toList();

User _internalUser({required InternalRole role, required List<String> scopes}) {
  return User(
    id: 'user-${role.name}',
    lastname: 'Test',
    firstname: 'Staff',
    phoneNumber: '+2250101010101',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: InternalProfile(
      id: 'profile-${role.name}',
      role: role,
      roleLabel: role.name,
    ),
    scopes: scopes,
  );
}

User _supportUser() {
  return User(
    id: 'user-support',
    lastname: 'Support',
    firstname: 'Fatou',
    phoneNumber: '+2250101010199',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: const InternalProfile(
      id: 'profile-support',
      role: InternalRole.support,
      roleLabel: 'Support',
    ),
    scopes: const [],
  );
}

User _customerUser() {
  return User(
    id: 'customer-1',
    lastname: 'Client',
    firstname: 'Voyageur',
    phoneNumber: '+2250101010103',
    userType: UserType.customer,
    scopes: const [],
  );
}