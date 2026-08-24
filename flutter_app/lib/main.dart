import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;

import 'database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.init();
  runApp(const PlantsApp());
}

// Botanical Inventory design tokens (from Stitch DESIGN.md).
const Color kPrimary = Color(0xFF2D5A27);
const Color kPrimaryDark = Color(0xFF154212);
const Color kSurface = Color(0xFFFFF8F5);
const Color kCardBorder = Color(0xFFE7E5E4);
const Color kPanelTint = Color(0xFFF7EFEB);
const Color kOnSurface = Color(0xFF1E1B19);
const Color kOnSurfaceVariant = Color(0xFF42493E);
const Color kStatusBg = Color(0xFFDCEFD6);
const Color kStatusGreen = Color(0xFF22A146);
const Color kDanger = Color(0xFFBA1A1A);
const Color kBgGradientTop = Color(0xFFEAF3E6);
const Color kBgGradientBottom = Color(0xFFD3E7CB);

class PlantsApp extends StatelessWidget {
  const PlantsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: kPrimary,
      onPrimary: Colors.white,
      primaryContainer: kStatusBg,
      onPrimaryContainer: kPrimaryDark,
      secondary: const Color(0xFF5E5E5E),
      onSecondary: Colors.white,
      surface: kSurface,
      onSurface: kOnSurface,
      onSurfaceVariant: kOnSurfaceVariant,
      surfaceContainerHighest: const Color(0xFFE9E1DD),
      outlineVariant: const Color(0xFFDDD8D3),
      error: kDanger,
      onError: Colors.white,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plantregistratie',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: kPrimary,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            color: kPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.01,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kCardBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kCardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kCardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kOnSurface,
            side: const BorderSide(color: kCardBorder),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xE6FFFFFF),
          indicatorColor: kStatusBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected) ? kPrimary : kOnSurfaceVariant,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? kPrimary : kOnSurfaceVariant,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF4ECE8),
          selectedColor: kPrimary,
          labelStyle: const TextStyle(color: kOnSurfaceVariant, fontWeight: FontWeight.w600),
          secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          side: const BorderSide(color: kCardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      builder: (context, child) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kBgGradientTop, kBgGradientBottom],
          ),
        ),
        child: child,
      ),
      home: const HomePage(),
    );
  }
}

String formatQuantity(int value) {
  final digits = value.abs().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return value < 0 ? '-$formatted' : formatted;
}

String historyAction(String action) => switch (action) {
      'created' => 'Aangemaakt',
      'added' => 'Toegevoegd',
      'removed' => 'Verwijderd',
      'corrected' => 'Gecorrigeerd',
      'edited' => 'Bewerkt',
      'distributed' => 'Verdeeld',
      _ => action,
    };

int? defaultQuantityForSize(List<Choice> sizes, int? sizeId) {
  for (final size in sizes) {
    if (size.id == sizeId) {
      return size.defaultQuantity;
    }
  }
  return null;
}

String formatDateTime(int value) {
  final date = DateTime.fromMillisecondsSinceEpoch(value);
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}-${two(date.month)}-${date.year} ${two(date.hour)}:${two(date.minute)}';
}

DateTime dateOnly(int value) {
  final date = DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime(date.year, date.month, date.day);
}

String dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (date == today) return 'Vandaag';
  if (date == today.subtract(const Duration(days: 1))) return 'Gisteren';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}-${two(date.month)}-${date.year}';
}

Future<Choice?> showChoiceDialog(BuildContext context, String title, List<Choice> choices) async {
  var query = '';
  return showDialog<Choice>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final filtered = choices.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
          title: Row(
            children: [
              Expanded(child: Text('Kies $title')),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), tooltip: 'Sluiten'),
            ],
          ),
          content: SizedBox(
            width: 520,
            height: 480,
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Zoeken...'),
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
                            return ListTile(title: Text(item.name), onTap: () => Navigator.pop(context, item));
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
      if (item.id == selectedId) { selected = item; break; }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kOnSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)),
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
              style: TextStyle(color: selected == null ? kOnSurfaceVariant : kOnSurface),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({required this.label, required this.controller, required this.onChanged, this.min = 0});
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
          Text(label, style: const TextStyle(color: kOnSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kCardBorder),
            ),
            child: Row(
              children: [
                IconButton(onPressed: () => _bump(-1), icon: const Icon(Icons.remove), color: kOnSurfaceVariant, tooltip: 'Minder'),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: kOnSurface),
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                IconButton(onPressed: () => _bump(1), icon: const Icon(Icons.add), color: kPrimary, tooltip: 'Meer'),
              ],
            ),
          ),
        ],
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _inventoryKey = GlobalKey<_InventoryPageState>();
  final _stockKey = GlobalKey<_StockPageState>();
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            InventoryPage(key: _inventoryKey),
            StockPage(key: _stockKey),
            const ManagementPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) {
            setState(() => _index = value);
            if (value == 0) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _inventoryKey.currentState?.refresh(),
              );
            } else if (value == 1) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _stockKey.currentState?.refresh(),
              );
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Registraties',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Voorraad',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Beheer',
            ),
          ],
        ),
      );
}

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
  Map<int,int> _subCounts = {};
  Map<int, List<DistributionRow>> _distributions = {};
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSubDepartments();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubDepartments() async {
    final subDepartments = await _database.choices(MasterType.subDepartments);
    if (!mounted) return;
    final wasNull = _filter.subDepartmentId == null;
    setState(() {
      _subDepartments = subDepartments;
      if (_filter.subDepartmentId != null && !subDepartments.any((entry) => entry.id == _filter.subDepartmentId)) {
        _filter = _filter.copyWith(subDepartmentId: null);
      }
      if (_filter.subDepartmentId == null && subDepartments.isNotEmpty) {
        _filter = _filter.copyWith(subDepartmentId: subDepartments.first.id);
      }
    });
    // If previously there was no subDepartment selected and now we set a default, reload to apply it
    if (wasNull && _filter.subDepartmentId != null) {
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
    return rows.map((row) => row.copyWith(sequenceNumber: sequence[row.id] ?? row.sequenceNumber ?? row.id)).toList();
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    final rows = _numberRowsBySubDepartment(await _database.inventory(_searchController.text, _filter));
    final distributions = await _database.distributionsForIds(rows.map((row) => row.id).toList());
    final countsRows = await _database.inventory('', const InventoryFilter());
    final Map<int,int> counts = {};
    final choices = _subDepartments.isEmpty ? await _database.choices(MasterType.subDepartments) : _subDepartments;
    for (final choice in choices) {
      counts[choice.id] = countsRows.where((r) => r.subDepartment == choice.name).length;
    }
    if (mounted) setState(() { _rows = rows; _distributions = distributions; _subCounts = counts; _loading = false; });
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
      await _database.distribute(inventoryId: row.id, lineId: result.lineId, sizeId: result.sizeId, quantity: result.quantity);
      await _reload();
    } on StateError catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<void> _editDistribution(InventoryRow row, DistributionRow distribution) async {
    final lines = await _database.choices(MasterType.lines);
    if (!mounted) return;
    final result = await showDialog<_DistributionEditResult>(
      context: context,
      builder: (_) => _DistributionEditDialog(distribution: distribution, lines: lines, available: row.quantity),
    );
    if (result == null) return;
    try {
      if (result.delete) {
        await _database.removeDistribution(distribution.id);
      } else {
        await _database.updateDistribution(distributionId: distribution.id, lineId: result.lineId, quantity: result.quantity);
      }
      await _reload();
    } on StateError catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _reload);
  }

  void _applySubDepartmentFilter(int? subDepartmentId) {
    setState(() {
      _filter = _filter.copyWith(subDepartmentId: subDepartmentId);
    });
    _reload();
  }

  Future<void> _openEditor([int? id, int? copyFromId]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditorPage(
          recordId: id,
          copyFromId: copyFromId,
          initialSubDepartmentId: _filter.subDepartmentId,
        ),
      ),
    );
    if (changed == true) await _reload();
  }

  Future<void> _copy(int id) async {
    await _openEditor(null, id);
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registratie verwijderen?'),
        content: const Text('Weet je zeker dat je deze registratie wilt verwijderen?'),
        actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleren')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verwijderen')),
        ],
      ),
    );
    if (confirmed == true) {
      await _database.deleteRecord(id);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<InventoryRow>>{};
    for (final row in _rows) {
      grouped.putIfAbsent(dateOnly(row.updatedAt), () => []).add(row);
    }
    Choice? selectedSubDepartment;
    for (final entry in _subDepartments) {
      if (entry.id == _filter.subDepartmentId) {
        selectedSubDepartment = entry;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSubDepartment == null ? 'Registraties' : 'Registraties • ${selectedSubDepartment.name}'),
      ),
      floatingActionButton: FloatingActionButton(
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
             decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Zoeken...'),
           ),
          ),
          if (_subDepartments.isNotEmpty)
           SizedBox(
             height: 48,
             child: ListView(
               padding: const EdgeInsets.symmetric(horizontal: 12),
               scrollDirection: Axis.horizontal,
               children: [
                 for (final subDepartment in _subDepartments)
                   Padding(
                     padding: const EdgeInsets.only(right: 8),
                     child: ChoiceChip(
                       label: Text('${subDepartment.name} (${_subCounts[subDepartment.id] ?? 0})'),
                       selected: _filter.subDepartmentId == subDepartment.id,
                       onSelected: (_) => _applySubDepartmentFilter(subDepartment.id),
                     ),
                   ),
               ],
             ),
           ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(child: Text('Nog geen registraties gevonden.'))
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 96),
                          children: [
                            for (final group in grouped.entries) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                                child: Text(
                                  '${dateLabel(group.key)} (${group.value.length})',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                              for (final row in group.value) _InventoryCard(
                                row: row,
                                distributions: _distributions[row.id] ?? const [],
                                onEdit: () => _openEditor(row.id),
                                onCopy: () => _copy(row.id),
                                onDelete: () => _delete(row.id),
                                onHistory: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => HistoryPage(row: row))),
                                onDistribute: () => _distribute(row),
                                onEditDistribution: (distribution) => _editDistribution(row, distribution),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatefulWidget {
  const _InventoryCard({required this.row, required this.distributions, required this.onEdit, required this.onCopy, required this.onDelete, required this.onHistory, required this.onDistribute, required this.onEditDistribution});
  final InventoryRow row;
  final List<DistributionRow> distributions;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onHistory;
  final VoidCallback onDistribute;
  final void Function(DistributionRow) onEditDistribution;

  @override
  State<_InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<_InventoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final distributions = widget.distributions;
    final total = row.quantity + distributions.fold<int>(0, (sum, d) => sum + d.quantity);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          row.plant,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kOnSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (distributions.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: kStatusBg, borderRadius: BorderRadius.circular(6)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call_split, size: 14, color: kPrimaryDark),
                              SizedBox(width: 4),
                              Text('Verdeeld', style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w700, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kStatusGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Nr. ${row.sequenceNumber ?? row.id}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: kOnSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: kOnSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${row.department} › ${row.subDepartment}',
                          style: const TextStyle(color: kOnSurfaceVariant, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Maat: ${row.size}', style: const TextStyle(color: kOnSurfaceVariant, fontSize: 14)),
                  if (!_expanded) ...[
                    const SizedBox(height: 6),
                    if (distributions.isEmpty)
                      Row(
                        children: [
                          Expanded(child: Text('Lijn ${row.line}', style: const TextStyle(color: kOnSurface, fontWeight: FontWeight.w600, fontSize: 14))),
                          Text('Aantal ${formatQuantity(row.quantity)}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Totaal: ${formatQuantity(total)}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                  ],
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kPanelTint,
                  borderRadius: BorderRadius.circular(8),
                  border: distributions.isNotEmpty ? const Border(left: BorderSide(color: kPrimary, width: 4)) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (distributions.isNotEmpty) ...[
                      const Text('Origineel', style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        _CardMetric(label: 'Lijn', value: row.line),
                        _CardMetric(label: 'Aantal', value: formatQuantity(row.quantity), highlight: true),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
              if (distributions.isNotEmpty) ...[
                for (final distribution in distributions) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => widget.onEditDistribution(distribution),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: kPanelTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _CardMetric(label: 'Lijn', value: distribution.line),
                          _CardMetric(label: 'Aantal', value: formatQuantity(distribution.quantity), highlight: true),
                          const Expanded(child: Align(alignment: Alignment.centerRight, child: Icon(Icons.edit_outlined, size: 18, color: kOnSurfaceVariant))),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Totaal: ${formatQuantity(total)}',
                    style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(onPressed: widget.onDistribute, icon: const Icon(Icons.call_split, color: kPrimary), tooltip: 'Verdelen'),
                  IconButton(onPressed: widget.onEdit, icon: const Icon(Icons.edit_outlined, color: kOnSurfaceVariant), tooltip: 'Bewerken'),
                  IconButton(onPressed: widget.onCopy, icon: const Icon(Icons.copy_outlined, color: kOnSurfaceVariant), tooltip: 'Kopiëren'),
                  IconButton(onPressed: widget.onHistory, icon: const Icon(Icons.history, color: kOnSurfaceVariant), tooltip: 'Geschiedenis'),
                  IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, color: kDanger), tooltip: 'Verwijderen'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: kOnSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: highlight ? kPrimary : kOnSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

class _DistributeResult {
  const _DistributeResult({required this.quantity, required this.lineId, required this.sizeId});
  final int quantity;
  final int lineId;
  final int sizeId;
}

class _DistributeDialog extends StatefulWidget {
  const _DistributeDialog({required this.row, required this.lines, required this.sizes});
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
      if (size.name == widget.row.size) { _sizeId = size.id; break; }
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _confirm() {
    final quantity = int.tryParse(_quantity.text);
    if (quantity == null || quantity <= 0 || _lineId == null || _sizeId == null) {
      setState(() => _error = 'Kies een lijn, maat en een geldig aantal.');
      return;
    }
    if (quantity > widget.row.quantity) {
      setState(() => _error = 'Er zijn maar ${formatQuantity(widget.row.quantity)} planten beschikbaar.');
      return;
    }
    Navigator.pop(context, _DistributeResult(quantity: quantity, lineId: _lineId!, sizeId: _sizeId!));
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
                child: Text('Beschikbaar: ${formatQuantity(widget.row.quantity)}', style: const TextStyle(color: kOnSurfaceVariant)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Aantal'),
              ),
              const SizedBox(height: 12),
              ChoiceField(label: 'Lijn', choices: widget.lines, selectedId: _lineId, onSelected: (choice) => setState(() => _lineId = choice.id)),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: kDanger))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          FilledButton(onPressed: _confirm, child: const Text('Verdelen')),
        ],
      );
}

class _DistributionEditResult {
  const _DistributionEditResult({required this.quantity, required this.lineId, this.delete = false});
  final int quantity;
  final int lineId;
  final bool delete;
}

class _DistributionEditDialog extends StatefulWidget {
  const _DistributionEditDialog({required this.distribution, required this.lines, required this.available});
  final DistributionRow distribution;
  final List<Choice> lines;
  final int available;

  @override
  State<_DistributionEditDialog> createState() => _DistributionEditDialogState();
}

class _DistributionEditDialogState extends State<_DistributionEditDialog> {
  late final TextEditingController _quantity;
  late int? _lineId;
  String? _error;

  int get _max => widget.available + widget.distribution.quantity;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: widget.distribution.quantity.toString());
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
      setState(() => _error = 'Er zijn maar ${formatQuantity(_max)} planten beschikbaar.');
      return;
    }
    Navigator.pop(context, _DistributionEditResult(quantity: quantity, lineId: _lineId!));
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
                child: Text('Maximaal: ${formatQuantity(_max)}', style: const TextStyle(color: kOnSurfaceVariant)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Aantal'),
              ),
              const SizedBox(height: 12),
              ChoiceField(label: 'Lijn', choices: widget.lines, selectedId: _lineId, onSelected: (choice) => setState(() => _lineId = choice.id)),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: kDanger))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DistributionEditResult(quantity: widget.distribution.quantity, lineId: widget.distribution.lineId, delete: true)),
            style: TextButton.styleFrom(foregroundColor: kDanger),
            child: const Text('Verwijderen'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          FilledButton(onPressed: _confirm, child: const Text('Opslaan')),
        ],
      );
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, this.recordId, this.copyFromId, this.initialSubDepartmentId});
  final int? recordId;
  final int? copyFromId;
  final int? initialSubDepartmentId;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _database = AppDatabase.instance;
  final _quantity = TextEditingController();
  final _block = TextEditingController(text: '1');
  List<Choice> _plants = const [];
  List<Choice> _departments = const [];
  List<Choice> _subDepartments = const [];
  List<Choice> _lines = const [];
  List<Choice> _sizes = const [];
  int? _plantId;
  int? _departmentId;
  int? _subDepartmentId;
  int? _lineId;
  int? _sizeId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _block.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _database.choices(MasterType.plants),
      _database.choices(MasterType.departments),
      _database.choices(MasterType.subDepartments),
      _database.choices(MasterType.lines),
      _database.choices(MasterType.sizes),
    ]);
    InventoryRecordData? record;
    final sourceId = widget.recordId ?? widget.copyFromId;
    if (sourceId != null) record = await _database.record(sourceId);
    final copiedQuantity = widget.copyFromId == null
        ? null
        : defaultQuantityForSize(values[4], record?.sizeId);
    if (!mounted) return;
    setState(() {
      _plants = values[0];
      _departments = values[1];
      _subDepartments = values[2];
      _lines = values[3];
      _sizes = values[4];
      _plantId = record?.plantId;
      _departmentId = record?.departmentId;
      _subDepartmentId = record?.subDepartmentId ?? widget.initialSubDepartmentId;
      _lineId = record?.lineId;
      _sizeId = record?.sizeId;
      _block.text = '1';
      _quantity.text = widget.copyFromId != null
          ? copiedQuantity?.toString() ?? ''
          : record?.quantity.toString() ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantity.text);
    final multiplier = int.tryParse(_block.text);
    if (_plantId == null || _departmentId == null || _subDepartmentId == null || _lineId == null || _sizeId == null || quantity == null || quantity <= 0 || multiplier == null || multiplier <= 0) {
      setState(() => _error = 'Vul alle velden in en gebruik een geldig aantal groter dan nul.');
      return;
    }
    final saveQuantity = quantity * multiplier;
    if (widget.recordId == null) {
      final existing = await _database.matchingRecord(
        plantId: _plantId!,
        departmentId: _departmentId!,
        subDepartmentId: _subDepartmentId!,
        lineId: _lineId!,
        sizeId: _sizeId!,
      );
      if (existing != null && mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bestaande registratie gevonden'),
            content: Text(
              'Huidig aantal: ${formatQuantity(existing.quantity)}\n'
              'Toevoegen: ${formatQuantity(saveQuantity)}\n'
              'Nieuw totaal: ${formatQuantity(existing.quantity + saveQuantity)}',
            ),
            actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleren')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Toevoegen aan bestaande registratie')),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _database.saveRecord(
        id: widget.recordId,
        plantId: _plantId!,
        departmentId: _departmentId!,
        subDepartmentId: _subDepartmentId!,
        lineId: _lineId!,
        sizeId: _sizeId!,
        quantity: saveQuantity,
      );
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (error) {
      if (mounted) setState(() { _saving = false; _error = error.message.toString(); });
    } on DatabaseException {
      if (mounted) setState(() { _saving = false; _error = 'Opslaan is niet gelukt. Controleer de gekozen voorraadpositie.'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.recordId != null ? 'Registratie bewerken' : widget.copyFromId != null ? 'Registratie kopiëren' : 'Nieuwe registratie')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChoiceField(label: 'Plant', choices: _plants, selectedId: _plantId, onSelected: (choice) => setState(() => _plantId = choice.id)),
                          const SizedBox(height: 16),
                          ChoiceField(label: 'Afdeling', choices: _departments, selectedId: _departmentId, onSelected: (choice) => setState(() { _departmentId = choice.id; _lineId = null; })),
                          const SizedBox(height: 16),
                          ChoiceField(label: 'Onderafdeling', choices: _subDepartments, selectedId: _subDepartmentId, onSelected: (choice) => setState(() => _subDepartmentId = choice.id)),
                          const SizedBox(height: 16),
                          ChoiceField(label: 'Lijn', choices: _lines, selectedId: _lineId, onSelected: (choice) => setState(() => _lineId = choice.id)),
                          const SizedBox(height: 16),
                          _StepperField(
                            label: 'Blok',
                            controller: _block,
                            min: 1,
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          ChoiceField(label: 'Maat', choices: _sizes, selectedId: _sizeId, onSelected: (choice) => setState(() { _sizeId = choice.id; _quantity.text = choice.defaultQuantity?.toString() ?? ''; })),
                          const SizedBox(height: 16),
                          _StepperField(
                            label: 'Aantal',
                            controller: _quantity,
                            onChanged: () => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_totalPreview != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: kPanelTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Verwachte totaal:', style: TextStyle(color: kOnSurfaceVariant, fontSize: 16)),
                          Text(
                            formatQuantity(_totalPreview!),
                            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 22),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDanger, width: 2),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFF93000A), fontWeight: FontWeight.w500)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Opslaan...' : 'Opslaan'),
                    ),
                  ),
                ],
              ),
      );

  int? get _totalPreview {
    final quantity = int.tryParse(_quantity.text);
    final multiplier = int.tryParse(_block.text);
    if (quantity == null || quantity <= 0 || multiplier == null || multiplier <= 0) return null;
    return quantity * multiplier;
  }
}

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
  List<InventoryRow> _details = const [];
  final Map<MasterType, List<Choice>> _choices = {};
  int _total = 0;
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadChoices();
    reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChoices() async {
    for (final type in MasterType.values) {
      _choices[type] = await _database.choices(type);
    }
    if (!mounted) return;
    final wasNull = _filter.subDepartmentId == null;
    setState(() {
      // If current subDepartmentId is no longer available, clear it.
      if (_filter.subDepartmentId != null && !(_choices[MasterType.subDepartments] ?? []).any((entry) => entry.id == _filter.subDepartmentId)) {
        _filter = _filter.copyWith(subDepartmentId: null);
      }
      // If there was no subDepartment selected and we have choices, pick the first as default.
      if (_filter.subDepartmentId == null && (_choices[MasterType.subDepartments] ?? []).isNotEmpty) {
        _filter = _filter.copyWith(subDepartmentId: (_choices[MasterType.subDepartments] ?? [])[0].id);
      }
    });
    // If previously there was no subDepartment selected and now we set a default, reload to apply it.
    if (wasNull && _filter.subDepartmentId != null) await reload();
  }

  Future<void> refresh() async {
    final subDepartments = await _database.choices(MasterType.subDepartments);
    if (!mounted) return;
    setState(() {
      _choices[MasterType.subDepartments] = subDepartments;
      if (_filter.subDepartmentId != null && !subDepartments.any((entry) => entry.id == _filter.subDepartmentId)) {
        _filter = _filter.copyWith(subDepartmentId: null);
      }
      if (_filter.subDepartmentId == null && subDepartments.isNotEmpty) {
        _filter = _filter.copyWith(subDepartmentId: subDepartments.first.id);
      }
    });
    await reload();
  }

  Future<void> reload() async {
    if (mounted) setState(() => _loading = true);
    final results = await Future.wait<Object>([
      _database.inventoryTotal(_searchController.text, _filter),
      _database.inventoryPlantTotals(_searchController.text, _filter),
      _database.inventory(_searchController.text, _filter, includeDistributions: true),
    ]);
    if (!mounted) return;
    setState(() {
      _total = results[0] as int;
      _plants = results[1] as List<PlantInventoryTotal>;
      _details = results[2] as List<InventoryRow>;
      _loading = false;
    });
  }

  Future<void> _applySubDepartmentFilter(int? subDepartmentId) async {
    setState(() {
      _filter = _filter.copyWith(subDepartmentId: subDepartmentId);
    });
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
      if (choice.id == id) {
        return choice.name;
      }
    }
    return type.label;
  }

  Future<void> _chooseQuickFilter(MasterType type) async {
    final choices = _choices[type] ?? await _database.choices(type);
    if (!mounted) return;
    final selected = await showChoiceDialog(context, _filterLabel(type), choices);
    if (selected == null) return;
    setState(() {
      _filter = InventoryFilter(
        plantId: type == MasterType.plants ? selected.id : _filter.plantId,
        departmentId: type == MasterType.departments ? selected.id : _filter.departmentId,
        subDepartmentId: type == MasterType.subDepartments ? selected.id : _filter.subDepartmentId,
        lineId: type == MasterType.lines ? selected.id : _filter.lineId,
        sizeId: type == MasterType.sizes ? selected.id : _filter.sizeId,
      );
    });
    await reload();
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push<InventoryFilter>(context, MaterialPageRoute(builder: (_) => FiltersPage(initial: _filter)));
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
    for (final entry in _choices[MasterType.subDepartments] ?? const <Choice>[]) {
      if (entry.id == _filter.subDepartmentId) {
        selectedSubDepartment = entry;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSubDepartment == null ? 'Voorraad' : 'Voorraad • ${selectedSubDepartment.name}'),
      ),
      body: Column(
        children: [
          if ((_choices[MasterType.subDepartments] ?? const <Choice>[]).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: SizedBox(
                height: 52,
                child: ListView(
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final subDepartment in _choices[MasterType.subDepartments] ?? const <Choice>[])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(subDepartment.name),
                          selected: _filter.subDepartmentId == subDepartment.id,
                          onSelected: (_) => _applySubDepartmentFilter(subDepartment.id),
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          labelStyle: TextStyle(
                            color: _filter.subDepartmentId == subDepartment.id
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: _filter.subDepartmentId == subDepartment.id ? FontWeight.w700 : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: _filter.subDepartmentId == subDepartment.id
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                for (final type in MasterType.values.where((t) => t != MasterType.subDepartments && t != MasterType.blocks))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _selectedId(type) != null,
                      label: Text(_filterLabel(type)),
                      onSelected: (_) => _chooseQuickFilter(type),
                      selectedColor: const Color(0xFFDCFCE7),
                      backgroundColor: const Color(0xFFE5E7EB),
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: _selectedId(type) != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _selectedId(type) != null ? FontWeight.w700 : FontWeight.w500,
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
                OutlinedButton.icon(onPressed: _openFilters, icon: const Icon(Icons.filter_list), label: const Text('Filters')),
                const SizedBox(width: 8),
                                TextButton(onPressed: _filter.activeCount == 0 && _searchController.text.isEmpty ? null : _clearFilters, child: const Text('Wis filters')),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            final rows = _details.where((row) => row.plant == plant.plant).toList();
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              child: ExpansionTile(
                                title: Row(
                                  children: [
                                    Expanded(child: Text(plant.plant, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    Text(formatQuantity(plant.quantity), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                children: [
                                  for (final row in rows)
                                    ListTile(
                                      title: Text('${row.department} • ${row.subDepartment} • ${row.line} • ${row.size}'),
                                      subtitle: Text('Laatst gewijzigd: ${formatDateTime(row.updatedAt)}'),
                                      trailing: Text(formatQuantity(row.quantity), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => HistoryPage(row: row))),
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
                  Text(widget.row.plant, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${widget.row.department} • ${widget.row.subDepartment} • ${widget.row.line} • ${widget.row.size}'),
                  const SizedBox(height: 8),
                  Text('Huidige voorraad: ${formatQuantity(widget.row.quantity)}', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<InventoryHistoryEntry>>(
                future: _history,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) return const Center(child: Text('Nog geen geschiedenis beschikbaar.'));
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final sign = entry.changeAmount > 0 ? '+' : '';
                      return ListTile(
                        leading: Icon(entry.changeAmount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline),
                        title: Text(historyAction(entry.action)),
                        subtitle: Text(formatDateTime(entry.createdAt)),
                        trailing: Text('$sign${formatQuantity(entry.changeAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key, required this.initial});
  final InventoryFilter initial;

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  final _database = AppDatabase.instance;
  List<Choice> _plants = const [];
  List<Choice> _departments = const [];
  List<Choice> _subDepartments = const [];
  List<Choice> _lines = const [];
  List<Choice> _sizes = const [];
  late InventoryFilter _filter = widget.initial;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _database.choices(MasterType.plants),
      _database.choices(MasterType.departments),
      _database.choices(MasterType.subDepartments),
      _database.choices(MasterType.lines),
      _database.choices(MasterType.sizes),
    ]);
    if (mounted) setState(() { _plants=values[0]; _departments=values[1]; _subDepartments=values[2]; _lines=values[3]; _sizes=values[4]; _loading=false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Filters')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ChoiceField(label:'Plant',choices:_plants,selectedId:_filter.plantId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:c.id,departmentId:_filter.departmentId,subDepartmentId:_filter.subDepartmentId,lineId:_filter.lineId,sizeId:_filter.sizeId)),allowClear:true,onClear:()=>setState(()=>_filter=InventoryFilter(plantId:null,departmentId:_filter.departmentId,subDepartmentId:_filter.subDepartmentId,lineId:_filter.lineId,sizeId:_filter.sizeId))),
                  const SizedBox(height:12),
                  ChoiceField(label:'Afdeling',choices:_departments,selectedId:_filter.departmentId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:c.id,subDepartmentId:_filter.subDepartmentId,lineId:_filter.lineId,sizeId:_filter.sizeId)),allowClear:true,onClear:()=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:null,subDepartmentId:_filter.subDepartmentId,lineId:_filter.lineId,sizeId:_filter.sizeId))),
                  const SizedBox(height:12),
                  ChoiceField(label:'Onderafdeling',choices:_subDepartments,selectedId:_filter.subDepartmentId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:_filter.departmentId,subDepartmentId:c.id,lineId:_filter.lineId,sizeId:_filter.sizeId)),allowClear:true,onClear:()=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:_filter.departmentId,subDepartmentId:null,lineId:_filter.lineId,sizeId:_filter.sizeId))),
                  const SizedBox(height:12),
                  ChoiceField(label:'Lijn',choices:_lines,selectedId:_filter.lineId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:_filter.departmentId,subDepartmentId:_filter.subDepartmentId,lineId:c.id,sizeId:_filter.sizeId)),allowClear:true,onClear:()=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:_filter.departmentId,subDepartmentId:_filter.subDepartmentId,lineId:null,sizeId:_filter.sizeId))),
                  const SizedBox(height:12),
                  ChoiceField(label:'Maat',choices:_sizes,selectedId:_filter.sizeId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:_filter.departmentId,subDepartmentId:_filter.subDepartmentId,lineId:_filter.lineId,sizeId:c.id)),allowClear:true,onClear:()=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:_filter.departmentId,subDepartmentId:_filter.subDepartmentId,lineId:_filter.lineId,sizeId:null))),
                  const SizedBox(height:16),
                  FilledButton(onPressed:()=>Navigator.pop(context,_filter),child:const Text('Filters toepassen')),
                  TextButton(onPressed:()=>Navigator.pop(context,const InventoryFilter()),child:const Text('Filters wissen')),
                ],
              ),
      );
}

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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items=await _database.choices(_type);
    if(mounted)setState((){_items=items;_loading=false;});
  }

  Future<void> _editDialog([Choice? item]) async {
    final name=TextEditingController(text:item?.name??'');
    final quantity=TextEditingController(text:item?.defaultQuantity?.toString()??'');
    final saved=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
      title:Text(item==null?'${_type.label} toevoegen':'${_type.label} bewerken'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,autofocus:true,decoration:const InputDecoration(labelText:'Naam')),
        if(_type==MasterType.sizes || _type==MasterType.blocks)...[
          const SizedBox(height:12),
          TextField(controller:quantity,keyboardType:TextInputType.number,decoration:InputDecoration(labelText: _type==MasterType.sizes ? 'Standaardaantal' : 'Vermenigvuldiger'))
        ]
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Annuleren')),FilledButton(onPressed:(){if(name.text.trim().isNotEmpty&&(_type!=MasterType.sizes&&_type!=MasterType.blocks||int.tryParse(quantity.text)!=null))Navigator.pop(context,true);},child:const Text('Opslaan'))],
    ));
    if(saved==true){
      try{
        if(item==null){await _database.addMaster(_type,name.text,defaultQuantity:int.tryParse(quantity.text)??0);}else{await _database.updateMaster(_type,item.id,name.text,defaultQuantity:int.tryParse(quantity.text)??0);}
        await _load();
      }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Deze naam bestaat al of is ongeldig.')));}
    }
    name.dispose();quantity.dispose();
  }

  Future<void> _delete(Choice item) async {
    final confirmed=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Item verwijderen?'),content:Text('Weet je zeker dat je “${item.name}” wilt verwijderen?'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Annuleren')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Verwijderen'))]));
    if(confirmed==true){
      try{await _database.deleteMaster(_type,item.id);await _load();}
      catch(error){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString().replaceFirst('Bad state: ',''))));}
    }
  }

  @override
  Widget build(BuildContext context){
    final filtered=_items.where((item)=>item.name.toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(
      appBar:AppBar(title:const Text('Beheer')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editDialog(),
        tooltip: 'Toevoegen',
        child: const Icon(Icons.add),
      ),
      body:Column(children:[
        SizedBox(width:double.infinity,child:Padding(padding:const EdgeInsets.fromLTRB(8,4,8,0),child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Row(mainAxisSize:MainAxisSize.min,children:[for(final type in MasterType.values.where((type) => type != MasterType.blocks))Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:ChoiceChip(label:Text(type.label),selected:_type==type,onSelected:(_){setState((){_type=type;_loading=true;_search='';});_load();}))])))),
        Padding(padding:const EdgeInsets.all(12),child:TextField(onChanged:(value)=>setState(()=>_search=value),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'Zoeken...'))),
        Expanded(child:_loading?const Center(child:CircularProgressIndicator()):filtered.isEmpty?const Center(child:Text('Geen items gevonden.')):ListView.separated(padding:const EdgeInsets.only(bottom:88),itemCount:filtered.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,index){final item=filtered[index];return ListTile(
          title: Text(item.name),
          subtitle: _type == MasterType.sizes
              ? Text('Standaardaantal: ${item.defaultQuantity}')
              : _type == MasterType.blocks
                  ? Text('Vermenigvuldiger: ${item.defaultQuantity}')
                  : null,
          trailing: Wrap(children: [IconButton(onPressed: ()=>_editDialog(item), icon: const Icon(Icons.edit), tooltip: 'Bewerken'), IconButton(onPressed: ()=>_delete(item), icon: const Icon(Icons.delete), tooltip: 'Verwijderen')]),
        );})),
      ]),
    );
  }
}
