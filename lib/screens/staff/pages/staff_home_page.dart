import 'package:flutter/material.dart';

import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';
import 'package:catrans_app/widgets/staff/staff_metric_card.dart';
import 'package:catrans_app/widgets/staff/staff_scope_chip.dart';

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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Bonjour ${user.firstname.isEmpty ? user.fullName : user.firstname}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F056B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenue dans votre portail métier CA TRANS.',
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 760;
            final cards = [
              StaffMetricCard(
                title: 'Modules disponibles',
                value: menuItems.length.toString(),
                icon: Icons.apps,
                color: Colors.indigo,
              ),
              StaffMetricCard(
                title: 'Scopes métier',
                value: user.scopes.length.toString(),
                icon: Icons.verified_user,
                color: Colors.green,
              ),
              StaffMetricCard(
                title: station == null ? 'Périmètre global' : 'Gare affectée',
                value: station?.name ?? 'CA TRANS',
                icon: Icons.location_city,
                color: Colors.orange,
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
          title: 'Identité métier',
          children: [
            _InfoLine(label: 'Nom', value: user.fullName),
            _InfoLine(label: 'Email', value: user.email ?? '-'),
            _InfoLine(
                label: 'Rôle',
                value: profile?.roleLabel ?? profile?.role.name ?? '-'),
            if (station != null) _InfoLine(label: 'Gare', value: station.name),
            if (counter != null)
              _InfoLine(label: 'Guichet', value: counter.displayName),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Scopes principaux',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.scopes.isEmpty
                  ? const [StaffScopeChip(label: 'Aucun scope disponible')]
                  : user.scopes.take(12).map((scope) {
                      return StaffScopeChip(label: scope);
                    }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Modules préparés',
          children: menuItems.where((item) => item.id != 'home').map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: const Color(0xFF0F056B)),
              title: Text(item.title),
              subtitle: Text(item.nextStep),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Panel({required this.title, required this.children});

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
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
