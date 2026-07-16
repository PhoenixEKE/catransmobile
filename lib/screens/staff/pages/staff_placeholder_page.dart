import 'package:flutter/material.dart';

import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';
import 'package:catrans_app/widgets/staff/staff_scope_chip.dart';

class StaffPlaceholderPage extends StatelessWidget {
  final User user;
  final StaffMenuItem item;

  const StaffPlaceholderPage({
    super.key,
    required this.user,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final role = user.internalProfile?.roleLabel ??
        user.internalProfile?.role.name ??
        '-';
    final station = user.internalProfile?.station;
    final counter = user.internalProfile?.counter;
    final visibleScopes = item.usefulScopes.isEmpty
        ? user.scopes.take(8).toList()
        : item.usefulScopes;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, size: 44, color: const Color(0xFF0F056B)),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: const TextStyle(
                  color: Color(0xFF0F056B),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.moduleDescription,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              const Text(
                'Module en préparation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(item.nextStep),
              const SizedBox(height: 24),
              _InfoBox(
                title: 'Contexte utilisateur',
                lines: [
                  'Rôle : $role',
                  if (station != null) 'Gare : ${station.name}',
                  if (counter != null) 'Guichet : ${counter.displayName}',
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Scopes utiles',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleScopes.isEmpty
                    ? const [StaffScopeChip(label: 'Aucun scope dédié')]
                    : visibleScopes.map((scope) {
                        return StaffScopeChip(label: scope);
                      }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoBox({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              )),
        ],
      ),
    );
  }
}
