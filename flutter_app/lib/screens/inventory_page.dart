import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/choice_field.dart';
import '../widgets/inventory_card.dart';
import '../widgets/sub_department_chips.dart';
import 'editor_page.dart';
import 'history_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _database = AppDatabase.instance;
  final _searchController = TextEditingController();
  InventoryFilter _filter = const InventoryFilter();
  List<InventoryRow> _rows = const [];
  List<Choice> _subDepartments = const [];
  Map<int, int> _subCounts = {};
  Map<int, List<DistributionRow>> _distributions = {};
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _database.addListener(_onDataChanged);
    _loadSubDepartments();
    _reload();
  }

  @override
  void dispose() {
    _database.removeListener(_onDataChanged);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) refresh();
  }

  Future<void> _loadSubDepartments() async {
    final subDepartments = await _database.choices(MasterType.subDepartments);
    if (!mounted) return;
    final wasNull = _filter.subDepartmentId == null;
    final resolved =
        resolveDefaultSubDepartment(_filter.subDepartmentId, subDepartments);
    setState(() {
      _subDepartments = subDepartments;
      _filter = _filter.copyWith(subDepartmentId: resolved);
    });
    if (wasNull && resolved != null) {
      await _reload();
    }
  }

  Future<void> refresh() async {
    await _loadSubDepartments();
    await _reload();
  }

  List<InventoryRow> _numberRowsBySubDepartment(List<InventoryRow> rows) {
    final grouped = <String, List<InventoryRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.subDepartment, () => []).add(row);
    }
    final sequence = <int, int>{};
    for (final entry in grouped.entries) {
      final values = List<InventoryRow>.from(entry.value)
        ..sort((a, b) {
          final created = a.createdAt.compareTo(b.createdAt);
          return created != 0 ? created : a.id.compareTo(b.id);
        });
      for (var index = 0; index < values.length; index++) {
        sequence[values[index].id] = index + 1;
      }
    }
    return rows
        .map((row) => row.copyWith(
            sequenceNumber: sequence[row.id] ?? row.sequenceNumber ?? row.id))
        .toList();
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    final rows = _numberRowsBySubDepartment(
        await _database.inventory(_searchController.text, _filter));
    final distributions =
        await _database.distributionsForIds(rows.map((row) => row.id).toList());
    final counts = await _database.subDepartmentCounts();
    if (mounted) {
      setState(() {
        _rows = rows;
        _distributions = distributions;
        _subCounts = counts;
        _loading = false;
      });
    }
  }

  Future<void> _distribute(InventoryRow row) async {
    final lines = await _database.choices(MasterType.lines);
    final sizes = await _database.choices(MasterType.sizes);
    if (!mounted) return;
    final result = await showDialog<_DistributeResult>(
      context: context,
      builder: (_) => _DistributeDialog(row: row, lines: lines, sizes: sizes),
    );
    if (result == null) return;
    try {
      await _database.distribute(
          inventoryId: row.id,
          lineId: result.lineId,
          sizeId: result.sizeId,
          quantity: result.quantity);
    } on DomainException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _editDistribution(
      InventoryRow row, DistributionRow distribution) async {
    final lines = await _database.choices(MasterType.lines);
    if (!mounted) return;
    final result = await showDialog<_DistributionEditResult>(
      context: context,
      builder: (_) => _DistributionEditDialog(
          distribution: distribution, lines: lines, available: row.quantity),
    );
    if (result == null) return;
    try {
      if (result.delete) {
        await _database.removeDistribution(distribution.id);
      } else {
        await _database.updateDistribution(
            distributionId: distribution.id,
            lineId: result.lineId,
            quantity: result.quantity);
      }
    } on DomainException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _reload);
  }

  void _applySubDepartmentFilter(int? subDepartmentId) {
    setState(
        () => _filter = _filter.copyWith(subDepartmentId: subDepartmentId));
    _reload();
  }

  Future<void> _openEditor([int? id, int? copyFromId]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditorPage(
          recordId: id,
          copyFromId: copyFromId,
          initialSubDepartmentId: _filter.subDepartmentId,
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registratie verwijderen?'),
        content: const Text(
            'Weet je zeker dat je deze registratie wilt verwijderen?'),
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
    if (confirmed == true) {
      await _database.deleteRecord(id);
    }
  }

  List<Object> _buildListItems() {
    final grouped = <DateTime, List<InventoryRow>>{};
    for (final row in _rows) {
      grouped.putIfAbsent(dateOnly(row.updatedAt), () => []).add(row);
    }
    final items = <Object>[];
    for (final entry in grouped.entries) {
      items.add(_DateHeader('${dateLabel(entry.key)} (${entry.value.length})'));
      items.addAll(entry.value);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    Choice? selectedSubDepartment;
    for (final entry in _subDepartments) {
      if (entry.id == _filter.subDepartmentId) {
        selectedSubDepartment = entry;
        break;
      }
    }
    final items = _buildListItems();
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSubDepartment == null
            ? 'Registraties'
            : 'Registraties • ${selectedSubDepartment.name}'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-registraties',
        onPressed: () => _openEditor(),
        tooltip: 'Nieuwe registratie',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: _searchChanged,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), labelText: 'Zoeken...'),
            ),
          ),
          if (_subDepartments.isNotEmpty)
            SubDepartmentChips(
              choices: _subDepartments,
              selectedId: _filter.subDepartmentId,
              onSelected: _applySubDepartmentFilter,
              counts: _subCounts,
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(
                        child: Text('Nog geen registraties gevonden.'))
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            if (item is _DateHeader) {
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 4),
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                              );
                            }
                            final row = item as InventoryRow;
                            return InventoryCard(
                              row: row,
                              distributions: _distributions[row.id] ?? const [],
                              onEdit: () => _openEditor(row.id),
                              onCopy: () => _openEditor(null, row.id),
                              onDelete: () => _delete(row.id),
                              onHistory: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => HistoryPage(row: row))),
                              onDistribute: () => _distribute(row),
                              onEditDistribution: (distribution) =>
                                  _editDistribution(row, distribution),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DateHeader {
  const _DateHeader(this.label);
  final String label;
}

class _DistributeResult {
  const _DistributeResult(
      {required this.quantity, required this.lineId, required this.sizeId});
  final int quantity;
  final int lineId;
  final int sizeId;
}

class _DistributeDialog extends StatefulWidget {
  const _DistributeDialog(
      {required this.row, required this.lines, required this.sizes});
  final InventoryRow row;
  final List<Choice> lines;
  final List<Choice> sizes;

  @override
  State<_DistributeDialog> createState() => _DistributeDialogState();
}

class _DistributeDialogState extends State<_DistributeDialog> {
  final _quantity = TextEditingController();
  int? _lineId;
  int? _sizeId;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final size in widget.sizes) {
      if (size.name == widget.row.size) {
        _sizeId = size.id;
        break;
      }
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _confirm() {
    final quantity = int.tryParse(_quantity.text);
    if (quantity == null ||
        quantity <= 0 ||
        _lineId == null ||
        _sizeId == null) {
      setState(() => _error = 'Kies een lijn, maat en een geldig aantal.');
      return;
    }
    if (quantity > widget.row.quantity) {
      setState(() => _error =
          'Er zijn maar ${formatQuantity(widget.row.quantity)} planten beschikbaar.');
      return;
    }
    Navigator.pop(
        context,
        _DistributeResult(
            quantity: quantity, lineId: _lineId!, sizeId: _sizeId!));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Verdelen'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Beschikbaar: ${formatQuantity(widget.row.quantity)}',
                    style: const TextStyle(color: kOnSurfaceVariant)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Aantal'),
              ),
              const SizedBox(height: 12),
              ChoiceField(
                  label: 'Lijn',
                  choices: widget.lines,
                  selectedId: _lineId,
                  onSelected: (choice) => setState(() => _lineId = choice.id)),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child:
                        Text(_error!, style: const TextStyle(color: kDanger))),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren')),
          FilledButton(onPressed: _confirm, child: const Text('Verdelen')),
        ],
      );
}

class _DistributionEditResult {
  const _DistributionEditResult(
      {required this.quantity, required this.lineId, this.delete = false});
  final int quantity;
  final int lineId;
  final bool delete;
}

class _DistributionEditDialog extends StatefulWidget {
  const _DistributionEditDialog(
      {required this.distribution,
      required this.lines,
      required this.available});
  final DistributionRow distribution;
  final List<Choice> lines;
  final int available;

  @override
  State<_DistributionEditDialog> createState() =>
      _DistributionEditDialogState();
}

class _DistributionEditDialogState extends State<_DistributionEditDialog> {
  late final TextEditingController _quantity;
  late int? _lineId;
  String? _error;

  int get _max => widget.available + widget.distribution.quantity;

  @override
  void initState() {
    super.initState();
    _quantity =
        TextEditingController(text: widget.distribution.quantity.toString());
    _lineId = widget.distribution.lineId;
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _confirm() {
    final quantity = int.tryParse(_quantity.text);
    if (quantity == null || quantity <= 0 || _lineId == null) {
      setState(() => _error = 'Kies een lijn en een geldig aantal.');
      return;
    }
    if (quantity > _max) {
      setState(() =>
          _error = 'Er zijn maar ${formatQuantity(_max)} planten beschikbaar.');
      return;
    }
    Navigator.pop(
        context, _DistributionEditResult(quantity: quantity, lineId: _lineId!));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Verdeling bewerken'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Maximaal: ${formatQuantity(_max)}',
                    style: const TextStyle(color: kOnSurfaceVariant)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Aantal'),
              ),
              const SizedBox(height: 12),
              ChoiceField(
                  label: 'Lijn',
                  choices: widget.lines,
                  selectedId: _lineId,
                  onSelected: (choice) => setState(() => _lineId = choice.id)),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child:
                        Text(_error!, style: const TextStyle(color: kDanger))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
                context,
                _DistributionEditResult(
                    quantity: widget.distribution.quantity,
                    lineId: widget.distribution.lineId,
                    delete: true)),
            style: TextButton.styleFrom(foregroundColor: kDanger),
            child: const Text('Verwijderen'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren')),
          FilledButton(onPressed: _confirm, child: const Text('Opslaan')),
        ],
      );
}
