import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../database.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/choice_field.dart';
import '../widgets/stepper_field.dart';

class EditorPage extends StatefulWidget {
  const EditorPage(
      {super.key, this.recordId, this.copyFromId, this.initialSubDepartmentId});
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
      _subDepartmentId =
          record?.subDepartmentId ?? widget.initialSubDepartmentId;
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
    if (_plantId == null ||
        _departmentId == null ||
        _subDepartmentId == null ||
        _lineId == null ||
        _sizeId == null ||
        quantity == null ||
        quantity <= 0 ||
        multiplier == null ||
        multiplier <= 0) {
      setState(() => _error =
          'Vul alle velden in en gebruik een geldig aantal groter dan nul.');
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
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuleren')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Toevoegen aan bestaande registratie')),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
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
    } on DomainException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    } on DatabaseException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Opslaan is niet gelukt. Controleer de gekozen voorraadpositie.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.recordId != null
                ? 'Registratie bewerken'
                : widget.copyFromId != null
                    ? 'Registratie kopiëren'
                    : 'Nieuwe registratie')),
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
                          ChoiceField(
                              label: 'Plant',
                              choices: _plants,
                              selectedId: _plantId,
                              onSelected: (choice) =>
                                  setState(() => _plantId = choice.id)),
                          const SizedBox(height: 16),
                          ChoiceField(
                              label: 'Afdeling',
                              choices: _departments,
                              selectedId: _departmentId,
                              onSelected: (choice) => setState(() {
                                    _departmentId = choice.id;
                                    _lineId = null;
                                  })),
                          const SizedBox(height: 16),
                          ChoiceField(
                              label: 'Onderafdeling',
                              choices: _subDepartments,
                              selectedId: _subDepartmentId,
                              onSelected: (choice) =>
                                  setState(() => _subDepartmentId = choice.id)),
                          const SizedBox(height: 16),
                          ChoiceField(
                              label: 'Lijn',
                              choices: _lines,
                              selectedId: _lineId,
                              onSelected: (choice) =>
                                  setState(() => _lineId = choice.id)),
                          const SizedBox(height: 16),
                          StepperField(
                              label: 'Blok',
                              controller: _block,
                              min: 1,
                              onChanged: () => setState(() {})),
                          const SizedBox(height: 16),
                          ChoiceField(
                              label: 'Maat',
                              choices: _sizes,
                              selectedId: _sizeId,
                              onSelected: (choice) => setState(() {
                                    _sizeId = choice.id;
                                    _quantity.text =
                                        choice.defaultQuantity?.toString() ??
                                            '';
                                  })),
                          const SizedBox(height: 16),
                          StepperField(
                              label: 'Aantal',
                              controller: _quantity,
                              onChanged: () => setState(() {})),
                        ],
                      ),
                    ),
                  ),
                  if (_totalPreview != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                          color: kPanelTint,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Verwachte totaal:',
                              style: TextStyle(
                                  color: kOnSurfaceVariant, fontSize: 16)),
                          Text(formatQuantity(_totalPreview!),
                              style: const TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22)),
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
                        color: kErrorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDanger, width: 2),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: kOnErrorContainer,
                              fontWeight: FontWeight.w500)),
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
    if (quantity == null ||
        quantity <= 0 ||
        multiplier == null ||
        multiplier <= 0) {
      return null;
    }
    return quantity * multiplier;
  }
}
