import 'dart:async';

import 'package:flutter/material.dart';

import 'database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.init();
  runApp(const PlantsApp());
}

class PlantsApp extends StatelessWidget {
  const PlantsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Plantregistratie',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff397047)),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const InventoryPage(),
      );
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
          title: Text('Kies $title'),
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
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sluiten'))],
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
  });

  final String label;
  final List<Choice> choices;
  final int? selectedId;
  final ValueChanged<Choice> onSelected;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    Choice? selected;
    for (final item in choices) {
      if (item.id == selectedId) { selected = item; break; }
    }
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final result = await showChoiceDialog(context, label, choices);
        if (result != null) onSelected(result);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: allowClear && selected != null
              ? const Icon(Icons.close)
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(selected?.name ?? 'Selecteer $label', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
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
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    final rows = await _database.inventory(_searchController.text, _filter);
    if (mounted) setState(() { _rows = rows; _loading = false; });
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _reload);
  }

  Future<void> _openEditor([int? id]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditorPage(recordId: id)));
    if (changed == true) await _reload();
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push<InventoryFilter>(context, MaterialPageRoute(builder: (_) => FiltersPage(initial: _filter)));
    if (result != null) {
      setState(() => _filter = result);
      await _reload();
    }
  }

  Future<void> _copy(int id) async {
    final newId = await _database.copyRecord(id);
    await _reload();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registratie Nr. $newId is gekopieerd.')));
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
      grouped.putIfAbsent(dateOnly(row.createdAt), () => []).add(row);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registraties'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: _filter.activeCount > 0,
              label: Text('${_filter.activeCount}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            tooltip: 'Beheer',
            onPressed: () async {
              await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => const ManagementPage()));
              await _reload();
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Nieuwe registratie'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchChanged,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Zoeken...'),
            ),
          ),
          if (_filter.activeCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  Expanded(child: Text('  ${_filter.activeCount} filter${_filter.activeCount == 1 ? '' : 's'} actief')),
                  TextButton(
                    onPressed: () { setState(() => _filter = const InventoryFilter()); _reload(); },
                    child: const Text('Wissen'),
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
                              for (final row in group.value) _InventoryCard(row: row, onEdit: () => _openEditor(row.id), onCopy: () => _copy(row.id), onDelete: () => _delete(row.id)),
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

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.row, required this.onEdit, required this.onCopy, required this.onDelete});
  final InventoryRow row;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(row.plant, style: const TextStyle(fontWeight: FontWeight.bold))),
                Text('Nr. ${row.id}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text('${row.department}  •  ${row.line}  •  ${row.size}  •  ${row.quantity}'),
              Text('Aangemaakt: ${formatDateTime(row.createdAt)}', style: Theme.of(context).textTheme.labelSmall),
              Wrap(
                children: [
                  TextButton(onPressed: onEdit, child: const Text('Bewerken')),
                  TextButton(onPressed: onCopy, child: const Text('Kopiëren')),
                  TextButton(onPressed: onDelete, child: const Text('Verwijderen')),
                ],
              ),
            ],
          ),
        ),
      );
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, this.recordId});
  final int? recordId;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _database = AppDatabase.instance;
  final _quantity = TextEditingController();
  List<Choice> _plants = const [];
  List<Choice> _departments = const [];
  List<Choice> _lines = const [];
  List<Choice> _sizes = const [];
  int? _plantId;
  int? _departmentId;
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
    super.dispose();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _database.choices(MasterType.plants),
      _database.choices(MasterType.departments),
      _database.choices(MasterType.lines),
      _database.choices(MasterType.sizes),
    ]);
    InventoryRecordData? record;
    if (widget.recordId != null) record = await _database.record(widget.recordId!);
    if (!mounted) return;
    setState(() {
      _plants = values[0];
      _departments = values[1];
      _lines = values[2];
      _sizes = values[3];
      _plantId = record?.plantId;
      _departmentId = record?.departmentId;
      _lineId = record?.lineId;
      _sizeId = record?.sizeId;
      _quantity.text = record?.quantity.toString() ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantity.text);
    if (_plantId == null || _departmentId == null || _lineId == null || _sizeId == null || quantity == null || quantity <= 0) {
      setState(() => _error = 'Vul alle velden in en gebruik een geldig aantal groter dan nul.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    await _database.saveRecord(
      id: widget.recordId,
      plantId: _plantId!,
      departmentId: _departmentId!,
      lineId: _lineId!,
      sizeId: _sizeId!,
      quantity: quantity,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.recordId == null ? 'Nieuwe registratie' : 'Registratie bewerken')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ChoiceField(label: 'Plant', choices: _plants, selectedId: _plantId, onSelected: (choice) => setState(() => _plantId = choice.id)),
                  const SizedBox(height: 12),
                  ChoiceField(label: 'Afdeling', choices: _departments, selectedId: _departmentId, onSelected: (choice) => setState(() { _departmentId = choice.id; _lineId = null; })),
                  const SizedBox(height: 12),
                  ChoiceField(label: 'Lijn', choices: _lines, selectedId: _lineId, onSelected: (choice) => setState(() => _lineId = choice.id)),
                  const SizedBox(height: 12),
                  ChoiceField(label: 'Maat', choices: _sizes, selectedId: _sizeId, onSelected: (choice) => setState(() { _sizeId = choice.id; _quantity.text = choice.defaultQuantity?.toString() ?? ''; })),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Aantal'),
                  ),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Opslaan...' : 'Opslaan')),
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
      _database.choices(MasterType.lines),
      _database.choices(MasterType.sizes),
    ]);
    if (mounted) setState(() { _plants=values[0]; _departments=values[1]; _lines=values[2]; _sizes=values[3]; _loading=false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Filters')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ChoiceField(label:'Plant',choices:_plants,selectedId:_filter.plantId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:c.id,departmentId:_filter.departmentId,lineId:_filter.lineId,sizeId:_filter.sizeId))),
                  const SizedBox(height:12),
                  ChoiceField(label:'Afdeling',choices:_departments,selectedId:_filter.departmentId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:c.id,lineId:_filter.lineId,sizeId:_filter.sizeId))),
                  const SizedBox(height:12),
                  ChoiceField(label:'Lijn',choices:_lines,selectedId:_filter.lineId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:_filter.departmentId,lineId:c.id,sizeId:_filter.sizeId))),
                  const SizedBox(height:12),
                  ChoiceField(label:'Maat',choices:_sizes,selectedId:_filter.sizeId,onSelected:(c)=>setState(()=>_filter=InventoryFilter(plantId:_filter.plantId,departmentId:_filter.departmentId,lineId:_filter.lineId,sizeId:c.id))),
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
      content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,autofocus:true,decoration:const InputDecoration(labelText:'Naam')),if(_type==MasterType.sizes)...[const SizedBox(height:12),TextField(controller:quantity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Standaardaantal'))]]),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Annuleren')),FilledButton(onPressed:(){if(name.text.trim().isNotEmpty&&(_type!=MasterType.sizes||int.tryParse(quantity.text)!=null))Navigator.pop(context,true);},child:const Text('Opslaan'))],
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
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>_editDialog(),icon:const Icon(Icons.add),label:const Text('Toevoegen')),
      body:Column(children:[
        SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:8),child:Row(children:[for(final type in MasterType.values)Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:ChoiceChip(label:Text(type.label,maxLines:1),selected:_type==type,onSelected:(_){setState((){_type=type;_loading=true;_search='';});_load();}))])),
        Padding(padding:const EdgeInsets.all(12),child:TextField(onChanged:(value)=>setState(()=>_search=value),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'Zoeken...'))),
        Expanded(child:_loading?const Center(child:CircularProgressIndicator()):filtered.isEmpty?const Center(child:Text('Geen items gevonden.')):ListView.separated(padding:const EdgeInsets.only(bottom:88),itemCount:filtered.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,index){final item=filtered[index];return ListTile(title:Text(item.name),subtitle:item.defaultQuantity==null?null:Text('Standaardaantal: ${item.defaultQuantity}'),trailing:Wrap(children:[IconButton(onPressed:()=>_editDialog(item),icon:const Icon(Icons.edit),tooltip:'Bewerken'),IconButton(onPressed:()=>_delete(item),icon:const Icon(Icons.delete),tooltip:'Verwijderen')]));})),
      ]),
    );
  }
}
