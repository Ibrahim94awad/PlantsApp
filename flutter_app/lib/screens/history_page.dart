import 'package:flutter/material.dart';

import '../database.dart';
import '../format.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.row});
  final InventoryRow row;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final Future<List<InventoryHistoryEntry>> _history;

  @override
  void initState() {
    super.initState();
    _history = AppDatabase.instance.history(widget.row.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Geschiedenis')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.row.plant,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                      '${widget.row.department} • ${widget.row.subDepartment} • ${widget.row.line} • ${widget.row.size}'),
                  const SizedBox(height: 8),
                  Text(
                      'Huidige voorraad: ${formatQuantity(widget.row.quantity)}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<InventoryHistoryEntry>>(
                future: _history,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) {
                    return const Center(
                        child: Text('Nog geen geschiedenis beschikbaar.'));
                  }
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final sign = entry.changeAmount > 0 ? '+' : '';
                      return ListTile(
                        leading: Icon(entry.changeAmount >= 0
                            ? Icons.add_circle_outline
                            : Icons.remove_circle_outline),
                        title: Text(historyAction(entry.action)),
                        subtitle: Text(formatDateTime(entry.createdAt)),
                        trailing: Text(
                            '$sign${formatQuantity(entry.changeAmount)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}
