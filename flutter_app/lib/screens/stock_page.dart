import 'dart:async';

import 'package:flutter/material.dart';

import '../database.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/choice_dialog.dart';
import '../widgets/sub_department_chips.dart';
import 'filters_page.dart';
import 'history_page.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _database = AppDatabase.instance;
  final _searchController = TextEditingController();
  InventoryFilter _filter = const InventoryFilter();
  List<PlantInventoryTotal> _plants = const [];
  Map<String, List<InventoryRow>> _detailsByPlant = const {};
  final Map<MasterType, List<Choice>> _choices = {};
  int _total = 0;
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _database.addListener(_onDataChanged);
    _loadChoices();
    reload();
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

  List<Choice> get _subDepartmentChoices =>
      _choices[MasterType.subDepartments] ?? const <Choice>[];

  Future<void> _loadChoices() async {
    for (final type in MasterType.values) {
      _choices[type] = await _database.choices(type);
    }
    if (!mounted) return;
    final wasNull = _filter.subDepartmentId == null;
    final resolved = resolveDefaultSubDepartment(
        _filter.subDepartmentId, _subDepartmentChoices);
    setState(() => _filter = _filter.copyWith(subDepartmentId: resolved));
    if (wasNull && resolved != null) await reload();
  }

  Future<void> refresh() async {
    final subDepartments = await _database.choices(MasterType.subDepartments);
    if (!mounted) return;
    final resolved =
        resolveDefaultSubDepartment(_filter.subDepartmentId, subDepartments);
    setState(() {
      _choices[MasterType.subDepartments] = subDepartments;
      _filter = _filter.copyWith(subDepartmentId: resolved);
    });
    await reload();
  }

  Future<void> reload() async {
    if (mounted) setState(() => _loading = true);
    final results = await Future.wait<Object>([
      _database.inventoryTotal(_searchController.text, _filter),
      _database.inventoryPlantTotals(_searchController.text, _filter),
      _database.inventory(_searchController.text, _filter,
          includeDistributions: true),
    ]);
    if (!mounted) return;
    final details = results[2] as List<InventoryRow>;
    final byPlant = <String, List<InventoryRow>>{};
    for (final row in details) {
      byPlant.putIfAbsent(row.plant, () => []).add(row);
    }
    setState(() {
      _total = results[0] as int;
      _plants = results[1] as List<PlantInventoryTotal>;
      _detailsByPlant = byPlant;
      _loading = false;
    });
  }

  Future<void> _applySubDepartmentFilter(int? subDepartmentId) async {
    setState(
        () => _filter = _filter.copyWith(subDepartmentId: subDepartmentId));
    await reload();
  }

  int? _selectedId(MasterType type) => switch (type) {
        MasterType.plants => _filter.plantId,
        MasterType.departments => _filter.departmentId,
        MasterType.subDepartments => _filter.subDepartmentId,
        MasterType.lines => _filter.lineId,
        MasterType.sizes => _filter.sizeId,
        MasterType.blocks => null,
      };

  String _filterLabel(MasterType type) {
    final id = _selectedId(type);
    if (id == null) {
      return switch (type) {
        MasterType.plants => 'Plant',
        MasterType.departments => 'Afdeling',
        MasterType.subDepartments => 'Onderafdeling',
        MasterType.lines => 'Lijn',
        MasterType.sizes => 'Maat',
        MasterType.blocks => 'Blok',
      };
    }
    for (final choice in _choices[type] ?? const <Choice>[]) {
      if (choice.id == id) return choice.name;
    }
    return type.label;
  }

  Future<void> _chooseQuickFilter(MasterType type) async {
    final choices = _choices[type] ?? await _database.choices(type);
    if (!mounted) return;
    final selected =
        await showChoiceDialog(context, _filterLabel(type), choices);
    if (selected == null) return;
    setState(() {
      _filter = _filter.copyWith(
        plantId: type == MasterType.plants ? selected.id : _filter.plantId,
        departmentId:
            type == MasterType.departments ? selected.id : _filter.departmentId,
        subDepartmentId: type == MasterType.subDepartments
            ? selected.id
            : _filter.subDepartmentId,
        lineId: type == MasterType.lines ? selected.id : _filter.lineId,
        sizeId: type == MasterType.sizes ? selected.id : _filter.sizeId,
      );
    });
    await reload();
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push<InventoryFilter>(context,
        MaterialPageRoute(builder: (_) => FiltersPage(initial: _filter)));
    if (result == null) return;
    setState(() => _filter = result);
    await reload();
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    setState(() => _filter = const InventoryFilter());
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    Choice? selectedSubDepartment;
    for (final entry in _subDepartmentChoices) {
      if (entry.id == _filter.subDepartmentId) {
        selectedSubDepartment = entry;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSubDepartment == null
            ? 'Voorraad'
            : 'Voorraad • ${selectedSubDepartment.name}'),
      ),
      body: Column(
        children: [
          if (_subDepartmentChoices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: SubDepartmentChips(
                choices: _subDepartmentChoices,
                selectedId: _filter.subDepartmentId,
                onSelected: _applySubDepartmentFilter,
                variant: SubDepartmentChipVariant.themed,
              ),
            ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                for (final type in MasterType.values.where((t) =>
                    t != MasterType.subDepartments && t != MasterType.blocks))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _selectedId(type) != null,
                      label: Text(_filterLabel(type)),
                      onSelected: (_) => _chooseQuickFilter(type),
                      selectedColor: kFilterSelectedBg,
                      backgroundColor: kFilterNeutralBg,
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: _selectedId(type) != null
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _selectedId(type) != null
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                    onPressed: _openFilters,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filters')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed:
                      _filter.activeCount == 0 && _searchController.text.isEmpty
                          ? null
                          : _clearFilters,
                  child: const Text('Wis filters'),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${_filter.activeCount == 0 && _searchController.text.isEmpty ? 'Totaal aantal planten' : 'Totaal'}: ${formatQuantity(_total)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _plants.isEmpty
                    ? const Center(child: Text('Geen voorraad gevonden.'))
                    : RefreshIndicator(
                        onRefresh: reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _plants.length,
                          itemBuilder: (context, index) {
                            final plant = _plants[index];
                            final rows = _detailsByPlant[plant.plant] ??
                                const <InventoryRow>[];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              child: ExpansionTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                        child: Text(plant.plant,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600))),
                                    Text(formatQuantity(plant.quantity),
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                children: [
                                  for (final row in rows)
                                    ListTile(
                                      title: Text(
                                          '${row.department} • ${row.subDepartment} • ${row.line} • ${row.size}'),
                                      subtitle: Text(
                                          'Laatst gewijzigd: ${formatDateTime(row.updatedAt)}'),
                                      trailing: Text(
                                          formatQuantity(row.quantity),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      onTap: () => Navigator.push<void>(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  HistoryPage(row: row))),
                                    ),
                                ],
                              ),
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
