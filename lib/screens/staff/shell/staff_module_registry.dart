import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/admin/admin_dashboard_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/admin_operations_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/admin_transport_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/admin_users_home_screen.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_screen.dart';
import 'package:catrans_app/screens/staff/counter/counter_search_screen.dart';
import 'package:catrans_app/screens/staff/dashboard/station_dashboard_screen.dart';
import 'package:catrans_app/screens/staff/departures/station_departures_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_home_page.dart';
import 'package:catrans_app/screens/staff/reports/station_reports_screen.dart';
import 'package:catrans_app/screens/staff/shell/staff_navigation_request.dart';

class StaffMenuItem {
  final String id;
  final String title;
  final IconData icon;
  final String section;
  final String moduleDescription;
  final String nextStep;
  final List<String> usefulScopes;
  final bool isAvailable;

  const StaffMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.section = '',
    required this.moduleDescription,
    required this.nextStep,
    this.usefulScopes = const [],
    this.isAvailable = true,
  });

  static List<StaffMenuItem> forUser(User user) {
    return StaffModuleRegistry.menuItemsForUser(user);
  }
}

class StaffModuleContext {
  final User user;
  final StaffMenuItem selectedItem;
  final List<StaffMenuItem> menuItems;
  final String? stationId;
  final bool isStationSupervision;
  final ValueChanged<StaffNavigationRequest> onNavigate;
  final StaffNavigationRequest? navigationRequest;
  final VoidCallback clearNavigationRequest;

  const StaffModuleContext({
    required this.user,
    required this.selectedItem,
    required this.menuItems,
    required this.stationId,
    required this.isStationSupervision,
    required this.onNavigate,
    required this.navigationRequest,
    required this.clearNavigationRequest,
  });

  StaffNavigationRequest? navigationRequestForCurrentModule() {
    final request = navigationRequest;
    if (request == null) return null;
    final requestMenuId = StaffModuleRegistry.canonicalMenuId(request.menuId);
    final selectedMenuId = StaffModuleRegistry.canonicalMenuId(selectedItem.id);
    if (requestMenuId != selectedMenuId) return null;
    return request;
  }
}

typedef StaffModuleBuilder = Widget Function(StaffModuleContext context);

class StaffModuleDefinition {
  final String id;
  final String title;
  final IconData icon;
  final String section;
  final String moduleDescription;
  final String nextStep;
  final List<String> usefulScopes;
  final bool stationScoped;
  final StaffModuleBuilder builder;

  const StaffModuleDefinition({
    required this.id,
    required this.title,
    required this.icon,
    this.section = '',
    required this.moduleDescription,
    required this.nextStep,
    this.usefulScopes = const [],
    this.stationScoped = false,
    required this.builder,
  });

  StaffMenuItem toMenuItem({
    String? id,
    String? title,
    List<String>? usefulScopes,
  }) {
    return StaffMenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon,
      section: section,
      moduleDescription: moduleDescription,
      nextStep: nextStep,
      usefulScopes: usefulScopes ?? this.usefulScopes,
    );
  }
}

class StaffModuleRegistry {
  const StaffModuleRegistry._();

  static const homeId = 'home';
  static const adminDashboardId = 'admin_dashboard';
  static const adminUsersId = 'admin_users';
  static const adminTransportId = 'admin_transport';
  static const adminOperationsId = 'admin_operations';
  static const stationDashboardId = 'station_dashboard';
  static const departuresId = 'departures';
  static const stationReservationsId = 'station_reservations';
  static const boardingId = 'boarding';
  static const reportsId = 'traveler_requests';
  static const legacyReportsId = 'reports';

  static final List<StaffModuleDefinition> modules = [
    _homeDefinition,
    _adminDashboardDefinition,
    _adminUsersDefinition,
    _adminTransportDefinition,
    _adminOperationsDefinition,
    _stationDashboardDefinition,
    _stationDeparturesDefinition,
    _stationReservationsDefinition,
    _stationBoardingDefinition,
    _stationReportsDefinition,
  ];

  static final Map<String, StaffModuleDefinition> _byId = {
    for (final module in modules) module.id: module,
  };

  static StaffModuleDefinition? definitionForMenuItem(StaffMenuItem item) {
    if (item.id == homeId &&
        item.usefulScopes.contains(StaffPermissions.stationDashboardRead)) {
      return _stationDashboardDefinition;
    }
    return _byId[canonicalMenuId(item.id)];
  }

  static String canonicalMenuId(String id) {
    return id == legacyReportsId ? reportsId : id;
  }

  static bool isStationScoped(StaffMenuItem item) {
    return definitionForMenuItem(item)?.stationScoped ?? false;
  }

  static Widget buildContent(StaffModuleContext context) {
    final definition = definitionForMenuItem(context.selectedItem);
    if (definition == null) return const SizedBox.shrink();
    return definition.builder(context);
  }

  static List<StaffMenuItem> menuItemsForUser(User user) {
    final role = user.internalProfile?.role;
    final scopes = user.scopes.toSet();
    final isTechnicalSuperuser = user.isSuperuser;

    final roleItems = role == null && isTechnicalSuperuser
        ? [
            _home('Accueil'),
            _adminDashboard(),
            _adminUsers(),
            _adminTransport(),
            _adminOperations(),
            _stationDashboard(),
            _stationDepartures(),
            _stationReservations(),
            _stationBoarding(),
            _stationReports(),
          ]
        : switch (role) {
            InternalRole.admin => [
                _home('Accueil'),
                _adminDashboard(),
                _adminUsers(),
                _adminTransport(),
                _adminOperations(),
                _stationDashboard(),
                _stationDepartures(),
                _stationReservations(),
                _stationBoarding(),
                _stationReports(),
              ],
            InternalRole.director => [
                _home('Pilotage'),
                _adminDashboard(),
                _adminUsers(),
                _adminTransport(),
                _adminOperations(),
              ],
            InternalRole.station_manager => [
                _home('Tableau gare'),
                _stationDepartures(),
                _stationReservations(),
                _stationBoarding(),
                _stationReports(),
              ],
            InternalRole.cashier => [
                _stationDashboard(),
                _stationDepartures(),
                _stationReservations(),
                _stationBoarding(),
              ],
            InternalRole.station_agent => [
                _home('Embarquement'),
                _stationBoarding(
                  description:
                      'Départs du jour, manifeste et validation billet.',
                  nextStep:
                      'Ouvrez un départ, contrôlez le manifeste et validez les billets.',
                ),
              ],
            InternalRole.support => [
                _home('Support'),
              ],
            InternalRole.accounting => [
                _home('Comptabilité'),
              ],
            InternalRole.marketing => [
                _home('Marketing'),
              ],
            InternalRole.legacy_unknown || null => const <StaffMenuItem>[],
          };

    if (scopes.isEmpty && !isTechnicalSuperuser) {
      return roleItems;
    }

    final roleScopedItems = roleItems
        .where((item) => item.usefulScopes.isNotEmpty)
        .where((item) => _matchesItemScopes(
              item,
              scopes,
              isTechnicalSuperuser: isTechnicalSuperuser,
            ))
        .toList(growable: false);

    if (roleScopedItems.isNotEmpty) {
      if (_shouldKeepRoleHome(role, roleScopedItems)) {
        return [
          if (roleItems.isNotEmpty && roleItems.first.id == homeId)
            roleItems.first,
          ...roleScopedItems,
        ];
      }
      return roleScopedItems;
    }

    final scopeItems = _scopeFirstItems(scopes);
    if (scopeItems.isNotEmpty) return scopeItems;

    return roleItems;
  }

  static List<StaffMenuItem> _scopeFirstItems(Set<String> scopes) {
    final items = <StaffMenuItem>[];

    if (_hasAnyScope(scopes, _adminDashboardDefinition.usefulScopes)) {
      items.add(_adminDashboard());
    }

    if (_hasAnyScope(scopes, _adminUsersDefinition.usefulScopes)) {
      items.add(_adminUsers());
    }

    if (_hasAnyScope(scopes, _adminTransportDefinition.usefulScopes)) {
      items.add(_adminTransport());
    }

    if (_hasAnyScope(scopes, _adminOperationsDefinition.usefulScopes)) {
      items.add(_adminOperations());
    }

    if (_hasAnyScope(scopes, _stationDashboardDefinition.usefulScopes)) {
      items.add(_stationDashboard(id: homeId));
    }

    if (_hasAnyScope(scopes, _stationDeparturesDefinition.usefulScopes)) {
      items.add(_stationDepartures());
    }

    if (_hasAnyScope(scopes, _stationReservationsDefinition.usefulScopes)) {
      items.add(_stationReservations());
    }

    if (_hasAnyScope(scopes, _stationBoardingDefinition.usefulScopes)) {
      items.add(_stationBoarding());
    }

    if (_hasAnyScope(scopes, _stationReportsDefinition.usefulScopes)) {
      items.add(_stationReports());
    }

    return items;
  }

  static StaffMenuItem _home(String title, {List<String> scopes = const []}) {
    return _homeDefinition.toMenuItem(title: title, usefulScopes: scopes);
  }

  static StaffMenuItem _adminDashboard() {
    return _adminDashboardDefinition.toMenuItem();
  }

  static StaffMenuItem _adminUsers() {
    return _adminUsersDefinition.toMenuItem();
  }

  static StaffMenuItem _adminTransport() {
    return _adminTransportDefinition.toMenuItem();
  }

  static StaffMenuItem _adminOperations() {
    return _adminOperationsDefinition.toMenuItem();
  }

  static StaffMenuItem _stationDashboard({String id = stationDashboardId}) {
    return _stationDashboardDefinition.toMenuItem(id: id);
  }

  static StaffMenuItem _stationDepartures() {
    return _stationDeparturesDefinition.toMenuItem();
  }

  static StaffMenuItem _stationReservations() {
    return _stationReservationsDefinition.toMenuItem();
  }

  static StaffMenuItem _stationBoarding({
    String? description,
    String? nextStep,
  }) {
    if (description == null && nextStep == null) {
      return _stationBoardingDefinition.toMenuItem();
    }
    return StaffMenuItem(
      id: _stationBoardingDefinition.id,
      title: _stationBoardingDefinition.title,
      icon: _stationBoardingDefinition.icon,
      section: _stationBoardingDefinition.section,
      moduleDescription:
          description ?? _stationBoardingDefinition.moduleDescription,
      nextStep: nextStep ?? _stationBoardingDefinition.nextStep,
      usefulScopes: _stationBoardingDefinition.usefulScopes,
    );
  }

  static StaffMenuItem _stationReports() {
    return _stationReportsDefinition.toMenuItem();
  }

  static bool _hasAnyScope(Set<String> scopes, List<String> expectedScopes) {
    return expectedScopes.any(scopes.contains);
  }

  static bool _matchesItemScopes(
    StaffMenuItem item,
    Set<String> scopes, {
    required bool isTechnicalSuperuser,
  }) {
    if (isTechnicalSuperuser) return true;
    return item.usefulScopes.any(scopes.contains);
  }

  static bool _shouldKeepRoleHome(
    InternalRole? role,
    List<StaffMenuItem> scopedItems,
  ) {
    if (role == InternalRole.admin) {
      return scopedItems.any((item) => item.id.startsWith('admin_'));
    }
    return role == InternalRole.station_manager ||
        role == InternalRole.cashier ||
        role == InternalRole.station_agent;
  }
}

String? resolveInitialStaffMenuId({
  required List<StaffMenuItem> menuItems,
  required Set<String> scopes,
  InternalRole? role,
}) {
  if (menuItems.isEmpty) return null;

  final rolePreferredId = switch (role) {
    InternalRole.station_manager => StaffModuleRegistry.homeId,
    InternalRole.cashier => StaffModuleRegistry.stationDashboardId,
    InternalRole.station_agent => StaffModuleRegistry.boardingId,
    _ => null,
  };

  if (rolePreferredId != null &&
      menuItems.any((item) => item.id == rolePreferredId)) {
    return rolePreferredId;
  }

  if (scopes.isNotEmpty) {
    const priorityIds = [
      StaffModuleRegistry.adminDashboardId,
      StaffModuleRegistry.adminUsersId,
      StaffModuleRegistry.adminTransportId,
      StaffModuleRegistry.adminOperationsId,
      StaffModuleRegistry.stationDashboardId,
      StaffModuleRegistry.homeId,
      StaffModuleRegistry.departuresId,
      'reservation_search',
      StaffModuleRegistry.stationReservationsId,
      StaffModuleRegistry.boardingId,
      StaffModuleRegistry.reportsId,
    ];

    for (final id in priorityIds) {
      final matches = menuItems.where((item) {
        if (item.id != id) return false;
        if (item.usefulScopes.isEmpty) return false;
        return item.usefulScopes.any(scopes.contains);
      });
      if (matches.isNotEmpty) return matches.first.id;
    }
  }

  return menuItems.first.id;
}

final _homeDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.homeId,
  title: 'Accueil',
  icon: Icons.dashboard_outlined,
  moduleDescription: 'Accueil du portail personnel CA TRANS.',
  nextStep: 'Consultez vos indicateurs métier et ouvrez une action du menu.',
  builder: (context) {
    final isStationManager =
        context.user.internalProfile?.role == InternalRole.station_manager;
    final isStationDashboardAlias = context.selectedItem.usefulScopes
        .contains(StaffPermissions.stationDashboardRead);

    if (isStationManager || isStationDashboardAlias) {
      return StationDashboardScreen(
        user: context.user,
        stationId: context.stationId,
        onNavigate: context.onNavigate,
      );
    }

    return StaffHomePage(
      user: context.user,
      menuItems: context.menuItems,
    );
  },
);

final _adminDashboardDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.adminDashboardId,
  title: 'Tableau admin',
  icon: Icons.query_stats,
  section: 'Administration',
  moduleDescription: 'Vue consolidée des indicateurs métier CA TRANS.',
  nextStep: 'Suivez les indicateurs clés par date pour piloter l’activité.',
  usefulScopes: const [StaffPermissions.adminDashboardRead],
  builder: (context) => AdminDashboardHomeScreen(user: context.user),
);

final _adminUsersDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.adminUsersId,
  title: 'Utilisateurs internes',
  icon: Icons.manage_accounts,
  section: 'Administration',
  moduleDescription: 'Gestion des comptes personnel, rôles, gares et guichets.',
  nextStep:
      'Consultez, créez et mettez à jour les comptes internes autorisés.',
  usefulScopes: const [
    StaffPermissions.adminUsersRead,
    StaffPermissions.adminUsersManage,
  ],
  builder: (context) => AdminUsersHomeScreen(user: context.user),
);

final _adminTransportDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.adminTransportId,
  title: 'Transport',
  icon: Icons.route,
  section: 'Administration',
  moduleDescription: 'Référentiels transport, lignes, horaires et tarifs.',
  nextStep: 'Accédez aux référentiels transport déjà disponibles.',
  usefulScopes: const [
    StaffPermissions.adminTransportRead,
    StaffPermissions.adminTransportManage,
  ],
  builder: (context) => AdminTransportHomeScreen(user: context.user),
);

final _adminOperationsDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.adminOperationsId,
  title: 'Opérations admin',
  icon: Icons.event_seat,
  section: 'Administration',
  moduleDescription: 'Layouts, templates, départs et sièges côté admin.',
  nextStep: 'Accédez aux opérations admin déjà disponibles.',
  usefulScopes: const [
    StaffPermissions.adminOperationsRead,
    StaffPermissions.adminOperationsManage,
  ],
  builder: (context) => AdminOperationsHomeScreen(user: context.user),
);

final _stationDashboardDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.stationDashboardId,
  title: 'Tableau gare',
  icon: Icons.dashboard_outlined,
  section: 'Opérations gare',
  moduleDescription: 'Vue opérationnelle des ventes, recettes et alertes gare.',
  nextStep: 'Suivez les indicateurs opérationnels de la gare sélectionnée.',
  usefulScopes: const [
    StaffPermissions.stationDashboardRead,
    StaffPermissions.stationAllRead,
  ],
  stationScoped: true,
  builder: (context) => StationDashboardScreen(
    user: context.user,
    stationId: context.stationId,
    onNavigate: context.onNavigate,
  ),
);

final _stationDeparturesDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.departuresId,
  title: 'Départs du jour',
  icon: Icons.directions_bus,
  section: 'Opérations gare',
  moduleDescription: 'Suivi opérationnel des départs de la gare.',
  nextStep: 'Consultez et pilotez les départs du jour depuis cet espace.',
  usefulScopes: const [
    StaffPermissions.stationDeparturesRead,
    StaffPermissions.stationDeparturesManage,
    StaffPermissions.stationAllRead,
  ],
  stationScoped: true,
  builder: (context) {
    final request = context.navigationRequestForCurrentModule();
    return StationDeparturesScreen(
      user: context.user,
      stationId: context.stationId,
      initialDepartureId: request?.departureId,
      onInitialDepartureConsumed: context.clearNavigationRequest,
      onNavigate: context.onNavigate,
    );
  },
);

final _stationReservationsDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.stationReservationsId,
  title: 'Réservations',
  icon: Icons.confirmation_number,
  section: 'Opérations gare',
  moduleDescription: 'Recherche, consultation, tickets et vente cash gare.',
  nextStep: 'Recherchez une réservation ou créez une vente cash.',
  usefulScopes: const [
    StaffPermissions.stationReservationsRead,
    StaffPermissions.stationReservationsSearch,
    StaffPermissions.stationTicketsPrint,
    StaffPermissions.stationTicketsRead,
    StaffPermissions.stationSalesCash,
    StaffPermissions.stationAllRead,
  ],
  stationScoped: true,
  builder: (context) => CounterSearchScreen(
    stationId: context.stationId,
    supervisionMode: true,
  ),
);

final _stationBoardingDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.boardingId,
  title: 'Embarquement',
  icon: Icons.how_to_reg,
  section: 'Opérations gare',
  moduleDescription: 'Suivi du manifeste et validations embarquement.',
  nextStep:
      'Ouvrez les départs du jour, consultez le manifeste et validez les billets.',
  usefulScopes: const [
    StaffPermissions.boardingManifestRead,
    StaffPermissions.boardingValidate,
    StaffPermissions.boardingSummaryRead,
    StaffPermissions.stationAllRead,
  ],
  stationScoped: true,
  builder: (context) {
    final request = context.navigationRequestForCurrentModule();
    return BoardingScreen(
      stationId: context.stationId,
      initialDepartureId: request?.departureId,
      onInitialDepartureConsumed: context.clearNavigationRequest,
    );
  },
);

final _stationReportsDefinition = StaffModuleDefinition(
  id: StaffModuleRegistry.reportsId,
  title: 'Demandes voyageurs',
  icon: Icons.edit_calendar,
  section: 'Opérations gare',
  moduleDescription: 'Traitement des demandes de modification et annulation.',
  nextStep: 'Traitez les demandes voyageurs depuis cet espace.',
  usefulScopes: const [
    StaffPermissions.stationReportsManage,
    StaffPermissions.stationAllRead,
  ],
  stationScoped: true,
  builder: (context) => StationReportsScreen(
    user: context.user,
    stationId: context.stationId,
  ),
);
