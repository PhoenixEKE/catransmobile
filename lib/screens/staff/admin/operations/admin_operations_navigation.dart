import 'package:flutter/material.dart';

class AdminOperationsSection {
  final String id;
  final String label;
  final IconData icon;

  const AdminOperationsSection({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class AdminOperationsNavigation extends StatelessWidget {
  final String selectedSectionId;
  final List<AdminOperationsSection> sections;
  final ValueChanged<String> onSectionSelected;

  const AdminOperationsNavigation({
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
                label: Text(section.label),
                onSelected: (_) => onSectionSelected(section.id),
                selectedColor: const Color(0xFF0F056B),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF0F056B)
                      : const Color(0xFFD8DDEA),
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF232633),
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
