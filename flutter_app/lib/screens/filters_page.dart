import 'package:flutter/material.dart';

import '../database.dart';
import '../widgets/choice_field.dart';

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
    if (!mounted) return;
    setState(() {
      _plants = values[0];
      _departments = values[1];
      _subDepartments = values[2];
      _lines = values[3];
      _sizes = values[4];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Filters')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ChoiceField(
                    label: 'Plant',
                    choices: _plants,
                    selectedId: _filter.plantId,
                    allowClear: true,
                    onSelected: (choice) => setState(
                        () => _filter = _filter.copyWith(plantId: choice.id)),
                    onClear: () => setState(
                        () => _filter = _filter.copyWith(plantId: null)),
                  ),
                  const SizedBox(height: 12),
                  ChoiceField(
                    label: 'Afdeling',
                    choices: _departments,
                    selectedId: _filter.departmentId,
                    allowClear: true,
                    onSelected: (choice) => setState(() =>
                        _filter = _filter.copyWith(departmentId: choice.id)),
                    onClear: () => setState(
                        () => _filter = _filter.copyWith(departmentId: null)),
                  ),
                  const SizedBox(height: 12),
                  ChoiceField(
                    label: 'Onderafdeling',
                    choices: _subDepartments,
                    selectedId: _filter.subDepartmentId,
                    allowClear: true,
                    onSelected: (choice) => setState(() =>
                        _filter = _filter.copyWith(subDepartmentId: choice.id)),
                    onClear: () => setState(() =>
                        _filter = _filter.copyWith(subDepartmentId: null)),
                  ),
                  const SizedBox(height: 12),
                  ChoiceField(
                    label: 'Lijn',
                    choices: _lines,
                    selectedId: _filter.lineId,
                    allowClear: true,
                    onSelected: (choice) => setState(
                        () => _filter = _filter.copyWith(lineId: choice.id)),
                    onClear: () => setState(
                        () => _filter = _filter.copyWith(lineId: null)),
                  ),
                  const SizedBox(height: 12),
                  ChoiceField(
                    label: 'Maat',
                    choices: _sizes,
                    selectedId: _filter.sizeId,
                    allowClear: true,
                    onSelected: (choice) => setState(
                        () => _filter = _filter.copyWith(sizeId: choice.id)),
                    onClear: () => setState(
                        () => _filter = _filter.copyWith(sizeId: null)),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, _filter),
                      child: const Text('Filters toepassen')),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context, const InventoryFilter()),
                      child: const Text('Filters wissen')),
                ],
              ),
      );
}
