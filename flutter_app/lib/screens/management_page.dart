import 'package:flutter/material.dart';

import '../database.dart';

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  final _database = AppDatabase.instance;
  MasterType _type = MasterType.plants;
  List<Choice> _items = const [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _database.choices(_type);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  void _selectType(MasterType type) {
    setState(() {
      _type = type;
      _loading = true;
      _search = '';
    });
    _load();
  }

  Future<void> _editDialog([Choice? item]) async {
    final result = await showDialog<_MasterEditResult>(
      context: context,
      builder: (context) => _MasterEditDialog(type: _type, item: item),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await _database.addMaster(_type, result.name,
            defaultQuantity: result.defaultQuantity);
      } else {
        await _database.updateMaster(_type, item.id, result.name,
            defaultQuantity: result.defaultQuantity);
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Deze naam bestaat al of is ongeldig.')));
      }
    }
  }

  Future<void> _delete(Choice item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item verwijderen?'),
        content: Text('Weet je zeker dat je “${item.name}” wilt verwijderen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuleren')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verwijderen')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _database.deleteMaster(_type, item.id);
      await _load();
    } on DomainException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items
        .where(
            (item) => item.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Beheer')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-beheer',
        onPressed: () => _editDialog(),
        tooltip: 'Toevoegen',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final type in MasterType.values
                        .where((type) => type != MasterType.blocks))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(type.label),
                          selected: _type == type,
                          onSelected: (_) => _selectType(type),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), labelText: 'Zoeken...'),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Geen items gevonden.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: _type == MasterType.sizes
                                ? Text(
                                    'Standaardaantal: ${item.defaultQuantity}')
                                : _type == MasterType.blocks
                                    ? Text(
                                        'Vermenigvuldiger: ${item.defaultQuantity}')
                                    : null,
                            trailing: Wrap(
                              children: [
                                IconButton(
                                    onPressed: () => _editDialog(item),
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Bewerken'),
                                IconButton(
                                    onPressed: () => _delete(item),
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Verwijderen'),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _MasterEditResult {
  const _MasterEditResult(this.name, this.defaultQuantity);
  final String name;
  final int defaultQuantity;
}

class _MasterEditDialog extends StatefulWidget {
  const _MasterEditDialog({required this.type, this.item});
  final MasterType type;
  final Choice? item;

  @override
  State<_MasterEditDialog> createState() => _MasterEditDialogState();
}

class _MasterEditDialogState extends State<_MasterEditDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.item?.name ?? '');
  late final TextEditingController _quantity = TextEditingController(
      text: widget.item?.defaultQuantity?.toString() ?? '');

  bool get _needsQuantity =>
      widget.type == MasterType.sizes || widget.type == MasterType.blocks;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_name.text.trim().isEmpty) return;
    if (_needsQuantity && int.tryParse(_quantity.text) == null) return;
    Navigator.pop(context,
        _MasterEditResult(_name.text, int.tryParse(_quantity.text) ?? 0));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.item == null
            ? '${widget.type.label} toevoegen'
            : '${widget.type.label} bewerken'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Naam')),
            if (_needsQuantity) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: widget.type == MasterType.sizes
                        ? 'Standaardaantal'
                        : 'Vermenigvuldiger'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren')),
          FilledButton(onPressed: _confirm, child: const Text('Opslaan')),
        ],
      );
}
