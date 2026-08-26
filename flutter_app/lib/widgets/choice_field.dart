import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'choice_dialog.dart';

class ChoiceField extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.choices,
    required this.selectedId,
    required this.onSelected,
    this.allowClear = false,
    this.onClear,
  });

  final String label;
  final List<Choice> choices;
  final int? selectedId;
  final ValueChanged<Choice> onSelected;
  final bool allowClear;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    Choice? selected;
    for (final item in choices) {
      if (item.id == selectedId) {
        selected = item;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: kOnSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final result = await showChoiceDialog(context, label, choices);
            if (result != null) onSelected(result);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: allowClear && selected != null
                  ? IconButton(
                      onPressed: onClear,
                      tooltip: 'Wis selectie',
                      splashRadius: 18,
                      icon: const Icon(Icons.close),
                    )
                  : const Icon(Icons.keyboard_arrow_down),
            ),
            child: Text(
              selected?.name ?? 'Selecteer ${label.toLowerCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: selected == null ? kOnSurfaceVariant : kOnSurface),
            ),
          ),
        ),
      ],
    );
  }
}
