import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';

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
    final role = user.internalProfile?.role;
    final scopes = user.scopes.toSet();
    final isTechnicalSuperuser = user.isSuperuser;

    final roleItems = role == null && isTechnicalSuperuser
        ? [
            _home('Tableau de bord'),
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
                _home('Tableau de bord'),
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
                _home('Tableau de bord gare'),
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
                _item(
                  id: 'boarding',
                  title: 'Embarquement',
                  icon: Icons.how_to_reg,
                  description:
                      'Départs du jour, manifeste et validation billet.',
                  nextStep:
                      'Ouvrez un départ, contrôlez le manifeste et validez les billets.',
                  scopes: [
                    'boarding.manifest.read',
                    'boarding.validate',
                    'boarding.summary.read',
                  ],
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
          if (roleItems.isNotEmpty && roleItems.first.id == 'home')
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

    if (_hasAnyScope(scopes, const [StaffPermissions.adminDashboardRead])) {
      items.add(_adminDashboard());
    }

    if (_hasAnyScope(scopes, const [
      StaffPermissions.adminUsersRead,
      StaffPermissions.adminUsersManage,
    ])) {
      items.add(_adminUsers());
    }

    if (_hasAnyScope(scopes, const [
      StaffPermissions.adminTransportRead,
      StaffPermissions.adminTransportManage,
    ])) {
      items.add(_adminTransport());
    }

    if (_hasAnyScope(scopes, const [
      StaffPermissions.adminOperationsRead,
      StaffPermissions.adminOperationsManage,
    ])) {
      items.add(_adminOperations());
    }

    if (_hasAnyScope(scopes, const [
      StaffPermissions.stationDashboardRead,
      StaffPermissions.stationAllRead,
    ])) {
      items.add(_stationDashboard(id: 'home'));
    }

    if (_hasAnyScope(scopes, const [
      StaffPermissions.stationDeparturesRead,
      StaffPermissions.stationDeparturesManage,
      StaffPermissions.stationAllRead,
    ])) {
      items.add(_stationDepartures());
    }

    if (_hasAnyScope(scopes, const [
      StaffPermissions.stationReservationsRead,
      StaffPermissions.stationReservationsSearch,
      StaffPermissions.stationTicketsPrint,
      StaffPermissions.stationTicketsRead,
      StaffPermissions.stationSalesCash,
      StaffPermissions.stationAllRead,
    ])) {
      items.add(_stationReservations());
    }

    if (_hasAnyScope(scopes, const [
      StaffPermissions.boardingManifestRead,
      StaffPermissions.boardingValidate,
      StaffPermissions.boardingSummaryRead,
      StaffPermissions.stationAllRead,
    ])) {
      items.add(_stationBoarding());
    }

    if (_hasAnyScope(scopes, const [
      StaffPermissions.stationReportsManage,
      StaffPermissions.stationAllRead,
    ])) {
      items.add(_stationReports());
    }

    return items;
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

  static StaffMenuItem _adminDashboard() {
    return _item(
      id: 'admin_dashboard',
      title: 'Tableau admin',
      icon: Icons.query_stats,
      section: 'Administration',
      description: 'Vue consolidée des indicateurs métier CA TRANS.',
      nextStep: 'Suivez les indicateurs clés par date pour piloter l’activité.',
      scopes: const [StaffPermissions.adminDashboardRead],
    );
  }

  static StaffMenuItem _adminUsers() {
    return _item(
      id: 'admin_users',
      title: 'Utilisateurs internes',
      icon: Icons.manage_accounts,
      section: 'Administration',
      description: 'Gestion des comptes personnel, rôles, gares et guichets.',
      nextStep:
          'Consultez, créez et mettez à jour les comptes internes autorisés.',
      scopes: const [
        StaffPermissions.adminUsersRead,
        StaffPermissions.adminUsersManage,
      ],
    );
  }

  static StaffMenuItem _adminTransport() {
    return _item(
      id: 'admin_transport',
      title: 'Transport',
      icon: Icons.route,
      section: 'Administration',
      description: 'Référentiels transport, lignes, horaires et tarifs.',
      nextStep: 'Accédez aux référentiels transport déjà disponibles.',
      scopes: const [
        StaffPermissions.adminTransportRead,
        StaffPermissions.adminTransportManage,
      ],
    );
  }

  static StaffMenuItem _adminOperations() {
    return _item(
      id: 'admin_operations',
      title: 'Opérations admin',
      icon: Icons.event_seat,
      section: 'Administration',
      description: 'Layouts, templates, départs et sièges côté admin.',
      nextStep: 'Accédez aux opérations admin déjà disponibles.',
      scopes: const [
        StaffPermissions.adminOperationsRead,
        StaffPermissions.adminOperationsManage,
      ],
    );
  }

  static StaffMenuItem _home(String title, {List<String> scopes = const []}) {
    return _item(
      id: 'home',
      title: title,
      icon: Icons.dashboard_outlined,
      description: 'Accueil du portail personnel CA TRANS.',
      nextStep:
          'Consultez vos indicateurs métier et ouvrez une action du menu.',
      scopes: scopes,
    );
  }

  static StaffMenuItem _stationDashboard({String id = 'station_dashboard'}) {
    return _item(
      id: id,
      title: 'Tableau gare',
      icon: Icons.dashboard_outlined,
      section: 'Opérations gare',
      description: 'Vue opérationnelle des ventes, recettes et alertes gare.',
      nextStep: 'Suivez les indicateurs opérationnels de la gare sélectionnée.',
      scopes: const [
        StaffPermissions.stationDashboardRead,
        StaffPermissions.stationAllRead,
      ],
    );
  }

  static StaffMenuItem _stationDepartures() {
    return _item(
      id: 'departures',
      title: 'Départs du jour',
      icon: Icons.directions_bus,
      section: 'Opérations gare',
      description: 'Suivi opérationnel des départs de la gare.',
      nextStep: 'Consultez et pilotez les départs du jour depuis cet espace.',
      scopes: const [
        StaffPermissions.stationDeparturesRead,
        StaffPermissions.stationDeparturesManage,
        StaffPermissions.stationAllRead,
      ],
    );
  }

  static StaffMenuItem _stationReservations() {
    return _item(
      id: 'station_reservations',
      title: 'Réservations',
      icon: Icons.confirmation_number,
      section: 'Opérations gare',
      description: 'Recherche, consultation, tickets et vente cash gare.',
      nextStep: 'Recherchez une réservation ou créez une vente cash.',
      scopes: const [
        StaffPermissions.stationReservationsRead,
        StaffPermissions.stationReservationsSearch,
        StaffPermissions.stationTicketsPrint,
        StaffPermissions.stationTicketsRead,
        StaffPermissions.stationSalesCash,
        StaffPermissions.stationAllRead,
      ],
    );
  }

  static StaffMenuItem _stationBoarding() {
    return _item(
      id: 'boarding',
      title: 'Embarquement',
      icon: Icons.how_to_reg,
      section: 'Opérations gare',
      description: 'Suivi du manifeste et validations embarquement.',
      nextStep:
          'Ouvrez les départs du jour, consultez le manifeste et validez les billets.',
      scopes: const [
        StaffPermissions.boardingManifestRead,
        StaffPermissions.boardingValidate,
        StaffPermissions.boardingSummaryRead,
        StaffPermissions.stationAllRead,
      ],
    );
  }

  static StaffMenuItem _stationReports() {
    return _item(
      id: 'reports',
      title: 'Reports / annulations',
      icon: Icons.edit_calendar,
      section: 'Opérations gare',
      description: 'Traitement des demandes de report et annulation.',
      nextStep:
          'Traitez les demandes de report et d’annulation depuis cet espace.',
      scopes: const [
        StaffPermissions.stationReportsManage,
        StaffPermissions.stationAllRead,
      ],
    );
  }

  static StaffMenuItem _item({
    required String id,
    required String title,
    required IconData icon,
    String section = '',
    required String description,
    required String nextStep,
    List<String> scopes = const [],
    bool isAvailable = true,
  }) {
    return StaffMenuItem(
      id: id,
      title: title,
      icon: icon,
      section: section,
      moduleDescription: description,
      nextStep: nextStep,
      usefulScopes: scopes,
      isAvailable: isAvailable,
    );
  }
}

String? resolveInitialStaffMenuId({
  required List<StaffMenuItem> menuItems,
  required Set<String> scopes,
  InternalRole? role,
}) {
  if (menuItems.isEmpty) return null;

  final rolePreferredId = switch (role) {
    InternalRole.station_manager => 'home',
    InternalRole.cashier => 'station_dashboard',
    InternalRole.station_agent => 'boarding',
    _ => null,
  };

  if (rolePreferredId != null &&
      menuItems.any((item) => item.id == rolePreferredId)) {
    return rolePreferredId;
  }

  if (scopes.isNotEmpty) {
    const priorityIds = [
      'admin_dashboard',
      'admin_users',
      'admin_transport',
      'admin_operations',
      'station_dashboard',
      'home',
      'departures',
      'reservation_search',
      'station_reservations',
      'boarding',
      'reports',
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
