import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class StepperField extends StatelessWidget {
  const StepperField(
      {super.key,
      required this.label,
      required this.controller,
      required this.onChanged,
      this.min = 0});
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final int min;

  void _bump(int delta) {
    final current = int.tryParse(controller.text) ?? min;
    final next = current + delta;
    if (next < min) return;
    controller.text = next.toString();
    onChanged();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: kOnSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kCardBorder),
            ),
            child: Row(
              children: [
                IconButton(
                    onPressed: () => _bump(-1),
                    icon: const Icon(Icons.remove),
                    color: kOnSurfaceVariant,
                    tooltip: 'Minder'),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: kOnSurface),
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () => _bump(1),
                    icon: const Icon(Icons.add),
                    color: kPrimary,
                    tooltip: 'Meer'),
              ],
            ),
          ),
        ],
      );
}
