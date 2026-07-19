import 'package:flutter/material.dart';

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
          _item(
            id: 'administration',
            title: 'Administration',
            icon: Icons.admin_panel_settings,
            description: 'Pilotage global du portail CA TRANS.',
            nextStep:
                'Les outils d’administration seront disponibles progressivement.',
            scopes: ['admin.dashboard.read', 'admin.users.manage'],
          ),
          _item(
            id: 'transport',
            title: 'Transport',
            icon: Icons.route,
            description: 'Gestion des gares, lignes, horaires et tarifs.',
            nextStep:
                'Les référentiels transport seront disponibles dans cet espace.',
            scopes: ['admin.transport.manage'],
          ),
          _item(
            id: 'operations',
            title: 'Opérations',
            icon: Icons.event_seat,
            description: 'Suivi des départs, sièges et opérations terrain.',
            nextStep:
                'Les opérations terrain seront regroupées dans cet espace.',
            scopes: ['admin.operations.manage'],
          ),
          _item(
            id: 'statistics',
            title: 'Statistiques',
            icon: Icons.query_stats,
            description: 'Vue consolidée des indicateurs métier.',
            nextStep:
                'Le dashboard analytique sera branché sur les endpoints admin.',
            scopes: ['admin.dashboard.read'],
          ),
          if (hasScope('finance.read'))
            _item(
              id: 'finance',
              title: 'Finance',
              icon: Icons.account_balance_wallet,
              description: 'Lecture des revenus et paiements.',
              nextStep:
                  'Les rapports financiers seront accessibles depuis cet espace.',
              scopes: ['finance.read'],
            ),
        ],
      InternalRole.director => [
          _home('Pilotage'),
          _item(
            id: 'overview',
            title: 'Vue direction',
            icon: Icons.dashboard,
            description: 'Vue lecture globale pour la direction.',
            nextStep: 'Les tableaux de bord seront enrichis progressivement.',
            scopes: ['admin.dashboard.read'],
          ),
          _item(
            id: 'transport_read',
            title: 'Transport',
            icon: Icons.route,
            description: 'Consultation des référentiels transport.',
            nextStep: 'Les vues transport en lecture seront disponibles ici.',
            scopes: ['admin.transport.read'],
          ),
          if (hasScope('finance.read'))
            _item(
              id: 'finance',
              title: 'Finance',
              icon: Icons.payments,
              description: 'Consultation des indicateurs financiers.',
              nextStep:
                  'Les rapports financiers seront disponibles depuis cet espace.',
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
                'Le suivi des départs du jour sera disponible depuis cet espace.',
            scopes: ['station.departures.read', 'station.departures.manage'],
          ),
          _item(
            id: 'station_reservations',
            title: 'Réservations gare',
            icon: Icons.confirmation_number,
            description: 'Consultation des réservations liées à la gare.',
            nextStep:
                'Recherche et consultation des réservations gare disponibles.',
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
                'Le traitement des demandes sera disponible progressivement.',
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
                'Retrouvez une réservation, consultez le détail et ouvrez les tickets disponibles.',
            scopes: ['station.reservations.search', 'station.tickets.print'],
          ),
          _item(
            id: 'counter_reports',
            title: 'Reports / annulations',
            icon: Icons.assignment_return,
            description:
                'Traitement des demandes de report et d’annulation des voyageurs.',
            nextStep:
                'Ce module permettra de traiter les demandes de report et d’annulation des voyageurs.',
            scopes: [
              'station.reports.request',
              'station.cancellations.request'
            ],
            isAvailable: false,
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
            nextStep: 'La recherche support sera disponible depuis cet espace.',
            scopes: ['support.reservations.read'],
          ),
          _item(
            id: 'support_payments',
            title: 'Recherche paiement',
            icon: Icons.payments,
            description: 'Consultation des paiements et statuts Wave.',
            nextStep:
                'Les détails paiement seront consultables depuis cet espace.',
            scopes: ['support.payments.read'],
          ),
          _item(
            id: 'support_tickets',
            title: 'Recherche ticket',
            icon: Icons.airplane_ticket,
            description: 'Consultation des tickets générés.',
            nextStep: 'La recherche ticket sera disponible depuis cet espace.',
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
            nextStep: 'Les paiements seront consultables depuis cet espace.',
            scopes: ['finance.payments.read'],
          ),
          _item(
            id: 'financial_reports',
            title: 'Rapports financiers',
            icon: Icons.bar_chart,
            description: 'Préparation des exports et rapports financiers.',
            nextStep:
                'Les exports financiers seront disponibles depuis cet espace.',
            scopes: ['finance.reports.read', 'finance.exports.read'],
          ),
        ],
      InternalRole.marketing => [
          _home('Marketing'),
          _item(
            id: 'marketing_pending',
            title: 'Marketing non disponible',
            icon: Icons.campaign,
            description: 'Le rôle marketing est reconnu par le portail.',
            nextStep:
                'Les fonctionnalités marketing seront disponibles progressivement.',
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

    if (_hasAnyScope(scopes, const [
      'station.dashboard.read',
      'admin.dashboard.read',
    ])) {
      items.add(
        _home(
          scopes.contains('station.dashboard.read')
              ? 'Tableau de bord gare'
              : 'Tableau de bord',
          scopes: const ['station.dashboard.read', 'admin.dashboard.read'],
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
              'Le traitement des demandes sera disponible progressivement.',
          scopes: const ['station.reports.manage'],
        ),
      );
    }

    return items;
  }

  static bool _hasAnyScope(Set<String> scopes, List<String> expectedScopes) {
    return expectedScopes.any(scopes.contains);
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
