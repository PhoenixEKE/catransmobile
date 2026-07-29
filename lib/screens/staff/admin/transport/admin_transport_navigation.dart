import 'package:flutter/material.dart';

class AdminTransportSection {
  final String id;
  final String label;
  final IconData icon;
  final bool isAvailable;

  const AdminTransportSection({
    required this.id,
    required this.label,
    required this.icon,
    this.isAvailable = false,
  });
}

class AdminTransportNavigation extends StatelessWidget {
  final String selectedSectionId;
  final List<AdminTransportSection> sections;
  final ValueChanged<String> onSectionSelected;

  const AdminTransportNavigation({
    super.key,
    required this.selectedSectionId,
    required this.sections,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sections.map((section) {
            final selected = section.id == selectedSectionId;
            return SizedBox(
              width: compact ? double.infinity : null,
              child: ChoiceChip(
                selected: selected,
                avatar: Icon(
                  section.icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFF0F056B),
                ),
                label: Text(
                  section.isAvailable
                      ? section.label
                      : '${section.label} · indisponible',
                ),
                onSelected: section.isAvailable
                    ? (_) => onSectionSelected(section.id)
                    : null,
                selectedColor: const Color(0xFF0F056B),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF232633),
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: Colors.white,
                disabledColor: const Color(0xFFF1F3F8),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF0F056B)
                      : const Color(0xFFD8DDEA),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
