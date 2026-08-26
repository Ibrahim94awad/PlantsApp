import 'package:flutter/material.dart';

import '../models.dart';

enum SubDepartmentChipVariant { counted, themed }

/// Horizontal strip of sub-department filter chips, shared by the inventory and
/// stock screens. [variant] switches between the count-badge look and the
/// theme-colored look.
class SubDepartmentChips extends StatelessWidget {
  const SubDepartmentChips({
    super.key,
    required this.choices,
    required this.selectedId,
    required this.onSelected,
    this.counts,
    this.variant = SubDepartmentChipVariant.counted,
  });

  final List<Choice> choices;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final Map<int, int>? counts;
  final SubDepartmentChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final height = variant == SubDepartmentChipVariant.counted ? 48.0 : 52.0;
    return SizedBox(
      height: height,
      child: ListView(
        padding: variant == SubDepartmentChipVariant.counted
            ? const EdgeInsets.symmetric(horizontal: 12)
            : EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        children: [
          for (final subDepartment in choices)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(context, subDepartment),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, Choice subDepartment) {
    final selected = selectedId == subDepartment.id;
    if (variant == SubDepartmentChipVariant.counted) {
      final count = counts?[subDepartment.id] ?? 0;
      return ChoiceChip(
        label: Text('${subDepartment.name} ($count)'),
        selected: selected,
        onSelected: (_) => onSelected(subDepartment.id),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(subDepartment.name),
      selected: selected,
      onSelected: (_) => onSelected(subDepartment.id),
      selectedColor: scheme.primaryContainer,
      backgroundColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side:
          BorderSide(color: selected ? scheme.primary : scheme.outlineVariant),
    );
  }
}
