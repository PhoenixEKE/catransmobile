import 'package:flutter/material.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';
import 'package:catrans_app/widgets/staff/staff_metric_card.dart';

class StaffHomePage extends StatelessWidget {
  final User user;
  final List<StaffMenuItem> menuItems;

  const StaffHomePage({
    super.key,
    required this.user,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    final profile = user.internalProfile;
    final station = profile?.station;
    final counter = profile?.counter;
    final role = profile?.role;
    final firstName = user.firstname.isEmpty ? user.fullName : user.firstname;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Bonjour $firstName',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F056B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _welcomeMessage(role),
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 760;
            final cards = [
              StaffMetricCard(
                title: station == null ? 'Périmètre' : 'Gare',
                value: station?.name ?? 'CA TRANS',
                icon: Icons.location_city,
                color: Colors.orange,
              ),
              StaffMetricCard(
                title: 'Poste',
                value:
                    counter?.displayName ?? profile?.roleLabel ?? 'Personnel',
                icon: Icons.badge,
                color: Colors.indigo,
              ),
              StaffMetricCard(
                title: 'Actions disponibles',
                value: _businessActions.length.toString(),
                icon: Icons.task_alt,
                color: Colors.green,
              ),
            ];

            if (isNarrow) {
              return Column(
                children: cards
                    .map((card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ))
                    .toList(),
              );
            }

            return Row(
              children: cards
                  .map((card) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: card,
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        _Panel(
          title: _businessTitle(role),
          child: Text(
            _businessMessage(role),
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Actions rapides',
          child: Column(
            children: _businessActions
                .map((item) => _ActionLine(item: item))
                .toList(),
          ),
        ),
      ],
    );
  }

  List<StaffMenuItem> get _businessActions {
    return menuItems.where((item) => item.id != 'home').toList();
  }

  String _welcomeMessage(InternalRole? role) {
    switch (role) {
      case InternalRole.cashier:
        return 'Recherchez les réservations, consultez les dossiers voyageurs et imprimez les tickets générés.';
      case InternalRole.station_manager:
        return 'Suivez les opérations de votre gare et accompagnez les équipes terrain.';
      case InternalRole.station_agent:
        return 'Préparez le contrôle embarquement et le suivi des passagers.';
      case InternalRole.admin:
      case InternalRole.director:
        return 'Pilotez les activités CA TRANS depuis votre espace personnel.';
      case InternalRole.accounting:
        return 'Suivez les paiements et les informations financières utiles.';
      case InternalRole.support:
        return 'Accompagnez les voyageurs sur leurs réservations, paiements et tickets.';
      default:
        return 'Bienvenue dans votre portail métier CA TRANS.';
    }
  }

  String _businessTitle(InternalRole? role) {
    switch (role) {
      case InternalRole.cashier:
        return 'Espace guichet';
      case InternalRole.station_manager:
        return 'Supervision gare';
      case InternalRole.station_agent:
        return 'Espace embarquement';
      case InternalRole.accounting:
        return 'Espace comptabilité';
      case InternalRole.support:
        return 'Espace support';
      default:
        return 'Portail métier';
    }
  }

  String _businessMessage(InternalRole? role) {
    switch (role) {
      case InternalRole.cashier:
        return 'Utilisez “Réservations” pour retrouver une réservation, consulter le détail et accéder aux actions d’impression disponibles.';
      case InternalRole.station_manager:
        return 'Consultez les réservations de la gare et gardez une vue claire sur les prochaines opérations.';
      case InternalRole.station_agent:
        return 'Utilisez “Embarquement” pour ouvrir les départs du jour, consulter le manifeste et valider les billets.';
      default:
        return 'Sélectionnez une action dans le menu pour commencer votre travail.';
    }
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF0F056B),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  final StaffMenuItem item;

  const _ActionLine({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: const Color(0xFF0F056B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(item.moduleDescription),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
