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

  const StaffMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.moduleDescription,
    required this.nextStep,
    this.usefulScopes = const [],
  });

  static List<StaffMenuItem> forUser(User user) {
    final role = user.internalProfile?.role;
    final scopes = user.scopes.toSet();

    bool hasScope(String scope) => scopes.contains(scope);

    switch (role) {
      case InternalRole.admin:
        return [
          _home('Tableau de bord'),
          _item(
            id: 'administration',
            title: 'Administration',
            icon: Icons.admin_panel_settings,
            description: 'Pilotage global du portail CA TRANS.',
            nextStep:
                'Les référentiels et droits seront branchés progressivement.',
            scopes: ['admin.dashboard.read', 'admin.users.manage'],
          ),
          _item(
            id: 'transport',
            title: 'Transport',
            icon: Icons.route,
            description: 'Gestion des gares, lignes, horaires et tarifs.',
            nextStep:
                'Les APIs transport admin seront raccordées dans un prochain lot.',
            scopes: ['admin.transport.manage'],
          ),
          _item(
            id: 'operations',
            title: 'Opérations',
            icon: Icons.event_seat,
            description: 'Suivi des départs, sièges et opérations terrain.',
            nextStep:
                'Les écrans opérations seront intégrés après le socle portail.',
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
                  'Les rapports finance seront connectés dans un lot dédié.',
              scopes: ['finance.read'],
            ),
        ];
      case InternalRole.director:
        return [
          _home('Pilotage'),
          _item(
            id: 'overview',
            title: 'Vue direction',
            icon: Icons.dashboard,
            description: 'Vue lecture globale pour la direction.',
            nextStep: 'Les tableaux de bord seront branchés progressivement.',
            scopes: ['admin.dashboard.read'],
          ),
          _item(
            id: 'transport_read',
            title: 'Transport',
            icon: Icons.route,
            description: 'Consultation des référentiels transport.',
            nextStep: 'Les vues lecture transport seront raccordées plus tard.',
            scopes: ['admin.transport.read'],
          ),
          if (hasScope('finance.read'))
            _item(
              id: 'finance',
              title: 'Finance',
              icon: Icons.payments,
              description: 'Consultation des indicateurs financiers.',
              nextStep:
                  'Les rapports financiers seront branchés dans un prochain lot.',
              scopes: ['finance.read'],
            ),
        ];
      case InternalRole.station_manager:
        return [
          _home('Tableau de bord gare'),
          _item(
            id: 'departures',
            title: 'Départs du jour',
            icon: Icons.directions_bus,
            description: 'Suivi opérationnel des départs de la gare.',
            nextStep:
                'Les départs du jour seront branchés sur les APIs station.',
            scopes: ['station.departures.read', 'station.departures.manage'],
          ),
          _item(
            id: 'station_reservations',
            title: 'Réservations gare',
            icon: Icons.confirmation_number,
            description: 'Consultation des réservations liées à la gare.',
            nextStep:
                'La recherche réservation gare sera branchée au lot guichet/station.',
            scopes: ['station.reservations.read'],
          ),
          _item(
            id: 'boarding',
            title: 'Embarquement',
            icon: Icons.how_to_reg,
            description: 'Suivi du manifeste et validations embarquement.',
            nextStep:
                'Manifeste et validation QR seront branchés au lot embarquement.',
            scopes: ['boarding.manifest.read'],
          ),
          _item(
            id: 'reports',
            title: 'Reports / annulations',
            icon: Icons.edit_calendar,
            description: 'Traitement des demandes de report et annulation.',
            nextStep:
                'Les workflows de traitement seront raccordés progressivement.',
            scopes: ['station.reports.manage'],
          ),
        ];
      case InternalRole.cashier:
        return [
          _home('Guichet'),
          _item(
            id: 'reservation_search',
            title: 'Recherche réservation',
            icon: Icons.search,
            description: 'Recherche des réservations client au guichet.',
            nextStep:
                'Recherche, détail et impression ticket seront branchés au lot 5.3.',
            scopes: ['station.reservations.search'],
          ),
          _item(
            id: 'ticket_print',
            title: 'Impression ticket',
            icon: Icons.print,
            description:
                'Préparation de l’impression ou réimpression de tickets.',
            nextStep:
                'L’impression ticket sera raccordée après la recherche réservation.',
            scopes: ['station.tickets.print'],
          ),
          _item(
            id: 'counter_reports',
            title: 'Reports / annulations',
            icon: Icons.assignment_return,
            description:
                'Création de demandes de report et annulation au guichet.',
            nextStep:
                'Les demandes guichet seront branchées dans un lot métier dédié.',
            scopes: [
              'station.reports.request',
              'station.cancellations.request'
            ],
          ),
        ];
      case InternalRole.station_agent:
        return [
          _home('Embarquement'),
          _item(
            id: 'manifest',
            title: 'Manifeste',
            icon: Icons.list_alt,
            description: 'Consultation du manifeste passagers.',
            nextStep: 'Le manifeste sera branché sur les départs station.',
            scopes: ['boarding.manifest.read'],
          ),
          _item(
            id: 'qr_validation',
            title: 'Validation QR',
            icon: Icons.qr_code_scanner,
            description: 'Validation des tickets au moment de l’embarquement.',
            nextStep: 'La validation QR sera branchée au lot 5.4.',
            scopes: ['boarding.validate'],
          ),
        ];
      case InternalRole.support:
        return [
          _home('Support'),
          _item(
            id: 'support_reservations',
            title: 'Recherche réservation',
            icon: Icons.search,
            description: 'Recherche support sur les réservations client.',
            nextStep:
                'La recherche support sera branchée sur les APIs client/admin.',
            scopes: ['support.reservations.read'],
          ),
          _item(
            id: 'support_payments',
            title: 'Recherche paiement',
            icon: Icons.payments,
            description: 'Consultation des paiements et statuts Wave.',
            nextStep:
                'Les détails paiement seront raccordés dans un lot support.',
            scopes: ['support.payments.read'],
          ),
          _item(
            id: 'support_tickets',
            title: 'Recherche ticket',
            icon: Icons.airplane_ticket,
            description: 'Consultation des tickets générés.',
            nextStep: 'La recherche ticket sera branchée sur TicketApiService.',
            scopes: ['support.tickets.read'],
          ),
        ];
      case InternalRole.accounting:
        return [
          _home('Comptabilité'),
          _item(
            id: 'payments',
            title: 'Paiements',
            icon: Icons.receipt_long,
            description: 'Suivi comptable des paiements.',
            nextStep:
                'Les paiements seront branchés sur les endpoints finance.',
            scopes: ['finance.payments.read'],
          ),
          _item(
            id: 'financial_reports',
            title: 'Rapports financiers',
            icon: Icons.bar_chart,
            description: 'Préparation des exports et rapports financiers.',
            nextStep:
                'Les exports finance seront branchés dans un lot comptabilité.',
            scopes: ['finance.reports.read', 'finance.exports.read'],
          ),
        ];
      case InternalRole.marketing:
        return [
          _home('Marketing'),
          _item(
            id: 'marketing_pending',
            title: 'Marketing non disponible',
            icon: Icons.campaign,
            description: 'Le rôle marketing est reconnu par le portail.',
            nextStep:
                'Les fonctionnalités marketing seront définies dans un lot ultérieur.',
            scopes: ['marketing.read'],
          ),
        ];
      case InternalRole.legacy_unknown:
      case null:
        return [
          _home('Profil incomplet'),
        ];
    }
  }

  static StaffMenuItem _home(String title) {
    return _item(
      id: 'home',
      title: title,
      icon: Icons.dashboard_outlined,
      description: 'Accueil du portail personnel CA TRANS.',
      nextStep: 'Les indicateurs métier seront ajoutés progressivement.',
    );
  }

  static StaffMenuItem _item({
    required String id,
    required String title,
    required IconData icon,
    required String description,
    required String nextStep,
    List<String> scopes = const [],
  }) {
    return StaffMenuItem(
      id: id,
      title: title,
      icon: icon,
      moduleDescription: description,
      nextStep: nextStep,
      usefulScopes: scopes,
    );
  }
}
