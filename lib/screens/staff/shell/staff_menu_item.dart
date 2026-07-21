import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';

class StaffMenuItem {
  final String id;
  final String title;
  final IconData icon;
  final String moduleDescription;
  final String nextStep;
  final List<String> usefulScopes;
  final bool isAvailable;

  const StaffMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.moduleDescription,
    required this.nextStep,
    this.usefulScopes = const [],
    this.isAvailable = true,
  });

  static List<StaffMenuItem> forUser(User user) {
    final role = user.internalProfile?.role;
    final scopes = user.scopes.toSet();

    bool hasScope(String scope) => scopes.contains(scope);

    final roleItems = switch (role) {
      InternalRole.admin => [
          _home('Tableau de bord'),
          _adminDashboard(),
          _adminUsers(),
          _adminTransport(),
          _adminOperations(),
          if (hasScope('finance.read'))
            _item(
              id: 'finance',
              title: 'Finance',
              icon: Icons.account_balance_wallet,
              description: 'Lecture des revenus et paiements.',
              nextStep:
                  'Consultez les revenus et les paiements depuis cet espace.',
              scopes: ['finance.read'],
            ),
        ],
      InternalRole.director => [
          _home('Pilotage'),
          _adminDashboard(),
          _adminUsers(),
          _adminTransport(),
          _adminOperations(),
          if (hasScope('finance.read'))
            _item(
              id: 'finance',
              title: 'Finance',
              icon: Icons.payments,
              description: 'Consultation des indicateurs financiers.',
              nextStep:
                  'Consultez les indicateurs financiers depuis cet espace.',
              scopes: ['finance.read'],
            ),
        ],
      InternalRole.station_manager => [
          _home('Tableau de bord gare'),
          _item(
            id: 'departures',
            title: 'Départs du jour',
            icon: Icons.directions_bus,
            description: 'Suivi opérationnel des départs de la gare.',
            nextStep:
                'Consultez et pilotez les départs du jour depuis cet espace.',
            scopes: ['station.departures.read', 'station.departures.manage'],
          ),
          _item(
            id: 'station_reservations',
            title: 'Réservations gare',
            icon: Icons.confirmation_number,
            description: 'Consultation des réservations liées à la gare.',
            nextStep: 'Recherchez et consultez les réservations de la gare.',
            scopes: ['station.reservations.read'],
          ),
          _item(
            id: 'boarding',
            title: 'Embarquement',
            icon: Icons.how_to_reg,
            description: 'Suivi du manifeste et validations embarquement.',
            nextStep:
                'Ouvrez les départs du jour, consultez le manifeste et validez les billets.',
            scopes: [
              'station.departures.read',
              'boarding.manifest.read',
              'boarding.summary.read',
            ],
          ),
          _item(
            id: 'reports',
            title: 'Reports / annulations',
            icon: Icons.edit_calendar,
            description: 'Traitement des demandes de report et annulation.',
            nextStep:
                'Traitez les demandes de report et d’annulation depuis cet espace.',
            scopes: ['station.reports.manage'],
          ),
        ],
      InternalRole.cashier => [
          _home('Guichet'),
          _item(
            id: 'reservation_search',
            title: 'Réservations & tickets',
            icon: Icons.confirmation_number,
            description: 'Recherche, consultation et impression des tickets.',
            nextStep:
                'Retrouvez une réservation, consultez le détail et ouvrez les tickets.',
            scopes: ['station.reservations.search', 'station.tickets.print'],
          ),
        ],
      InternalRole.station_agent => [
          _home('Embarquement'),
          _item(
            id: 'boarding',
            title: 'Embarquement',
            icon: Icons.how_to_reg,
            description: 'Départs du jour, manifeste et validation billet.',
            nextStep:
                'Ouvrez un départ, contrôlez le manifeste et validez les billets.',
            scopes: [
              'station.departures.read',
              'boarding.manifest.read',
              'boarding.validate',
              'boarding.summary.read',
            ],
          ),
        ],
      InternalRole.support => [
          _home('Support'),
          _item(
            id: 'support_reservations',
            title: 'Recherche réservation',
            icon: Icons.search,
            description: 'Recherche support sur les réservations client.',
            nextStep: 'Recherchez les réservations support depuis cet espace.',
            scopes: ['support.reservations.read'],
          ),
          _item(
            id: 'support_payments',
            title: 'Recherche paiement',
            icon: Icons.payments,
            description: 'Consultation des paiements et statuts Wave.',
            nextStep:
                'Consultez les paiements et leurs statuts depuis cet espace.',
            scopes: ['support.payments.read'],
          ),
          _item(
            id: 'support_tickets',
            title: 'Recherche ticket',
            icon: Icons.airplane_ticket,
            description: 'Consultation des tickets générés.',
            nextStep: 'Consultez les tickets générés depuis cet espace.',
            scopes: ['support.tickets.read'],
          ),
        ],
      InternalRole.accounting => [
          _home('Comptabilité'),
          _item(
            id: 'payments',
            title: 'Paiements',
            icon: Icons.receipt_long,
            description: 'Suivi comptable des paiements.',
            nextStep: 'Consultez les paiements depuis cet espace.',
            scopes: ['finance.payments.read'],
          ),
          _item(
            id: 'financial_reports',
            title: 'Rapports financiers',
            icon: Icons.bar_chart,
            description: 'Préparation des exports et rapports financiers.',
            nextStep:
                'Préparez les exports et rapports financiers depuis cet espace.',
            scopes: ['finance.reports.read', 'finance.exports.read'],
          ),
        ],
      InternalRole.marketing => [
          _home('Marketing'),
          _item(
            id: 'marketing_pending',
            title: 'Marketing',
            icon: Icons.campaign,
            description: 'Le rôle marketing est reconnu par le portail.',
            nextStep: 'Les fonctionnalités marketing ne sont pas exposées ici.',
            scopes: ['marketing.read'],
          ),
        ],
      InternalRole.legacy_unknown || null => const <StaffMenuItem>[],
    };

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

    if (_hasAnyScope(scopes, const ['station.dashboard.read'])) {
      items.add(
        _home(
          'Tableau de bord gare',
          scopes: const ['station.dashboard.read'],
        ),
      );
    }

    if (_hasAnyScope(scopes, const [
      'station.departures.read',
      'station.departures.manage',
    ])) {
      items.add(
        _item(
          id: 'departures',
          title: 'Départs du jour',
          icon: Icons.directions_bus,
          description: 'Suivi opérationnel des départs de la gare.',
          nextStep:
              'Le suivi des départs du jour sera disponible depuis cet espace.',
          scopes: const [
            'station.departures.read',
            'station.departures.manage'
          ],
        ),
      );
    }

    if (_hasAnyScope(scopes, const [
      'station.reservations.search',
      'station.tickets.print',
      'station.tickets.read',
    ])) {
      items.add(
        _item(
          id: 'reservation_search',
          title: 'Réservations & tickets',
          icon: Icons.confirmation_number,
          description: 'Recherche, consultation et impression des tickets.',
          nextStep:
              'Retrouvez une réservation, consultez le détail et ouvrez les tickets disponibles.',
          scopes: const [
            'station.reservations.search',
            'station.tickets.print',
            'station.tickets.read',
          ],
        ),
      );
    }

    if (_hasAnyScope(scopes, const ['station.reservations.read'])) {
      items.add(
        _item(
          id: 'station_reservations',
          title: 'Réservations gare',
          icon: Icons.confirmation_number,
          description: 'Consultation des réservations liées à la gare.',
          nextStep:
              'Recherche et consultation des réservations gare disponibles.',
          scopes: const ['station.reservations.read'],
        ),
      );
    }

    if (_hasAnyScope(scopes, const [
      'boarding.manifest.read',
      'boarding.validate',
      'boarding.summary.read',
    ])) {
      items.add(
        _item(
          id: 'boarding',
          title: 'Embarquement',
          icon: Icons.how_to_reg,
          description: 'Départs du jour, manifeste et validation billet.',
          nextStep:
              'Ouvrez un départ, contrôlez le manifeste et validez les billets.',
          scopes: const [
            'boarding.manifest.read',
            'boarding.validate',
            'boarding.summary.read',
          ],
        ),
      );
    }

    if (_hasAnyScope(scopes, const ['station.reports.manage'])) {
      items.add(
        _item(
          id: 'reports',
          title: 'Reports / annulations',
          icon: Icons.edit_calendar,
          description: 'Traitement des demandes de report et annulation.',
          nextStep:
              'Traitez les demandes de report et d’annulation depuis cet espace.',
          scopes: const ['station.reports.manage'],
        ),
      );
    }

    return items;
  }

  static bool _hasAnyScope(Set<String> scopes, List<String> expectedScopes) {
    return expectedScopes.any(scopes.contains);
  }

  static StaffMenuItem _adminDashboard() {
    return _item(
      id: 'admin_dashboard',
      title: 'Tableau admin',
      icon: Icons.query_stats,
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
      nextStep: 'Les indicateurs métier seront ajoutés progressivement.',
      scopes: scopes,
    );
  }

  static StaffMenuItem _item({
    required String id,
    required String title,
    required IconData icon,
    required String description,
    required String nextStep,
    List<String> scopes = const [],
    bool isAvailable = true,
  }) {
    return StaffMenuItem(
      id: id,
      title: title,
      icon: icon,
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

  if (scopes.isNotEmpty) {
    const priorityIds = [
      'admin_dashboard',
      'admin_users',
      'admin_transport',
      'admin_operations',
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

  final rolePreferredId = switch (role) {
    InternalRole.station_manager => 'home',
    InternalRole.cashier => 'reservation_search',
    InternalRole.station_agent => 'boarding',
    _ => null,
  };

  if (rolePreferredId != null &&
      menuItems.any((item) => item.id == rolePreferredId)) {
    return rolePreferredId;
  }

  return menuItems.first.id;
}
