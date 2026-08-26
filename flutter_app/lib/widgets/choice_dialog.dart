import 'package:flutter/material.dart';

import '../models.dart';

Future<Choice?> showChoiceDialog(
    BuildContext context, String title, List<Choice> choices) async {
  var query = '';
  return showDialog<Choice>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final filtered = choices
            .where(
                (item) => item.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
          title: Row(
            children: [
              Expanded(child: Text('Kies $title')),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Sluiten'),
            ],
          ),
          content: SizedBox(
            width: 520,
            height: 480,
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search), labelText: 'Zoeken...'),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Geen items gevonden.'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return ListTile(
                                title: Text(item.name),
                                onTap: () => Navigator.pop(context, item));
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
